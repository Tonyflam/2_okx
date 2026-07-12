// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {SafeCast} from "v4-core/src/libraries/SafeCast.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";

/// @title MundialHook — the pool that plays the World Cup.
///
/// @notice A Uniswap v4 hook that runs a complete 8-team knockout World Cup
/// *inside* a single pool. Trading is the game:
///
///  - Fans pledge to one national team, once, forever (`joinTeam`).
///  - The tournament is a fixed 7-match knockout bracket (QF -> SF -> Final)
///    on a deterministic on-chain schedule.
///  - During a live match, every swap by a pledged fan is a *shot* for their
///    team; every `GOAL_THRESHOLD` units of swapped currency1 volume is a
///    *goal*. The team with more goals at full time wins.
///  - Draw at full time? Extra time is sudden death: the first goal wins
///    (a golden goal that settles the match in the same transaction).
///    Still level? Penalties: most shots win; then the lower seed advances.
///  - Fan swaps pay a *lower* LP fee than neutral swaps, cheapest while their
///    team is playing, cheapest of all during golden-goal extra time. The fee
///    schedule is fixed at compile time — no admin can change it.
///  - A small skim on fan swaps fills the Champions Pot held by the hook.
///    When the final settles, fans of the champion claim the pot pro rata to
///    the volume they traded for their team ("caps"). Whatever is unclaimed
///    after the claim window is donated to the pool's LPs. The deployer can
///    never touch it.
///
/// There is **no owner, no oracle, no randomness, and no upgradeability**.
/// Match results are a pure function of swap flow and time. Anyone can call
/// `poke()` to settle due matches; settlement also happens lazily on the next
/// swap.
///
/// @dev Trust and attribution notes (read before integrating):
///  - `tx.origin` is used solely to attribute *game* state (fee tier, shots,
///    caps). It never authorizes custody or movement of user funds. Swappers
///    using smart-contract accounts simply get neutral treatment (base fee,
///    no shots) because `tx.origin` will not match a pledged fan.
///  - The hook binds to exactly one dynamic-fee pool at initialization and
///    rejects all others.
contract MundialHook is IHooks, IUnlockCallback {
    using LPFeeLibrary for uint24;
    using SafeCast for uint256;

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------

    error NotPoolManager();
    error AlreadyInitialized();
    error NotInitialized();
    error WrongPool();
    error MustUseDynamicFee();
    error InvalidTeam();
    error AlreadyJoined();
    error TeamEliminated();
    error TournamentOver();
    error TournamentNotOver();
    error NotAFanOfChampion();
    error NothingToClaim();
    error AlreadyClaimed();
    error ClaimWindowClosed();
    error ClaimWindowOpen();
    error HookNotImplemented();
    error InvalidSchedule();
    error InvalidThreshold();

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------

    /// @notice A fan pledged to a team (one-time, irreversible).
    event FanJoined(address indexed fan, uint8 indexed team);
    /// @notice A fan swap counted as a shot for their team in a live match.
    event ShotTaken(address indexed fan, uint8 indexed team, uint8 indexed matchId, uint256 volume);
    /// @notice A team's cumulative match volume crossed one or more goal thresholds.
    event GoalScored(uint8 indexed team, uint8 indexed matchId, uint64 totalGoals);
    /// @notice A match was settled and the bracket advanced.
    event MatchSettled(uint8 indexed matchId, uint8 indexed winner, uint8 loser, uint64 goalsW, uint64 goalsL, Tiebreak tiebreak);
    /// @notice The final settled; claims are open.
    event ChampionCrowned(uint8 indexed team, uint256 pot0, uint256 pot1);
    /// @notice A champion fan claimed their share of the pot.
    event PotClaimed(address indexed fan, uint256 amount0, uint256 amount1);
    /// @notice Leftover pot donated to the pool's LPs.
    event PotDonatedToLPs(uint256 amount0, uint256 amount1);

    enum Tiebreak {
        None, // won on goals at full time
        GoldenGoal, // sudden-death goal in extra time
        Penalties, // more shots after extra time
        Seed // lower seed advances (total deadlock)
    }

    // ---------------------------------------------------------------------
    // Immutable configuration (no setters exist, by design)
    // ---------------------------------------------------------------------

    IPoolManager public immutable poolManager;

    /// @notice Tournament kickoff timestamp (match 0 starts here).
    uint64 public immutable kickoff;
    /// @notice Regulation play length per match, seconds.
    uint64 public immutable regulation;
    /// @notice Extra (sudden-death) time per match, seconds.
    uint64 public immutable extraTime;
    /// @notice Break between match slots, seconds.
    uint64 public immutable breakTime;
    /// @notice currency1 volume required per goal.
    uint256 public immutable goalThreshold;

    /// @notice LP fee for unpledged swappers / eliminated-team fans (pips, 1e-6).
    uint24 public constant FEE_NEUTRAL = 5000; // 0.50%
    /// @notice LP fee for fans whose team is still alive.
    uint24 public constant FEE_FAN_ALIVE = 2500; // 0.25%
    /// @notice LP fee for fans whose team is playing right now.
    uint24 public constant FEE_MATCH_LIVE = 1500; // 0.15%
    /// @notice LP fee during golden-goal extra time for playing-team fans.
    uint24 public constant FEE_GOLDEN_GOAL = 1000; // 0.10%
    /// @notice Champions Pot skim on fan swaps, in bips of the unspecified amount.
    uint256 public constant SKIM_BIPS = 20; // 0.20%
    uint256 internal constant BIPS_DENOMINATOR = 10_000;
    /// @notice How long champion fans have to claim after the final.
    uint64 public constant CLAIM_WINDOW = 30 days;

    uint8 public constant TEAM_COUNT = 8;
    uint8 public constant MATCH_COUNT = 7; // 4 QF + 2 SF + 1 F
    uint8 internal constant TBD = type(uint8).max;

    // ---------------------------------------------------------------------
    // Tournament state
    // ---------------------------------------------------------------------

    struct Match {
        uint8 teamA; // seed index, TBD until feeders settle
        uint8 teamB;
        uint32 shotsA; // fan swaps counted during the live window
        uint32 shotsB;
        uint128 volumeA; // currency1 volume during the live window
        uint128 volumeB;
        bool settled;
        uint8 winner;
    }

    /// @notice Team names (e.g. "Argentina"), fixed at deployment.
    bytes32[TEAM_COUNT] public teamNames;
    /// @notice False once a team is knocked out.
    bool[TEAM_COUNT] public alive;
    Match[MATCH_COUNT] internal _matches;
    /// @notice Index of the match currently in play / next to settle. MATCH_COUNT == tournament over.
    uint8 public currentMatch;
    /// @notice Champion seed index; TBD until the final settles.
    uint8 public champion = TBD;
    /// @notice Timestamp when the final settled.
    uint64 public finalizedAt;

    /// @notice fan => team seed + 1 (0 = never pledged).
    mapping(address => uint8) internal _fanTeamPlusOne;
    /// @notice Tournament-long currency1 volume a fan traded while pledged.
    mapping(address => uint256) public caps;
    /// @notice Sum of caps per team.
    uint256[TEAM_COUNT] public teamCaps;
    mapping(address => bool) public claimed;

    /// @notice Champions Pot balances held by this hook.
    uint256 public pot0;
    uint256 public pot1;

    // ---------------------------------------------------------------------
    // Pool binding
    // ---------------------------------------------------------------------

    PoolKey public poolKey;
    bool public poolBound;

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    /// @param _poolManager The canonical v4 PoolManager on this chain.
    /// @param _teamNames Eight team names, seed order 0..7. QFs: (0v1)(2v3)(4v5)(6v7).
    /// @param _kickoff Unix timestamp of match 0 kickoff. Must be in the future or now.
    /// @param _regulation Regulation seconds per match (> 0).
    /// @param _extraTime Sudden-death seconds per match (> 0).
    /// @param _breakTime Seconds between match slots.
    /// @param _goalThreshold currency1 volume per goal (> 0).
    constructor(
        IPoolManager _poolManager,
        bytes32[8] memory _teamNames,
        uint64 _kickoff,
        uint64 _regulation,
        uint64 _extraTime,
        uint64 _breakTime,
        uint256 _goalThreshold
    ) {
        if (_regulation == 0 || _extraTime == 0) revert InvalidSchedule();
        if (_goalThreshold == 0) revert InvalidThreshold();
        poolManager = _poolManager;
        teamNames = _teamNames;
        kickoff = _kickoff;
        regulation = _regulation;
        extraTime = _extraTime;
        breakTime = _breakTime;
        goalThreshold = _goalThreshold;

        // Seed the quarter-finals; later rounds are TBD.
        for (uint8 i = 0; i < 4; ++i) {
            _matches[i].teamA = i * 2;
            _matches[i].teamB = i * 2 + 1;
        }
        for (uint8 i = 4; i < MATCH_COUNT; ++i) {
            _matches[i].teamA = TBD;
            _matches[i].teamB = TBD;
        }
        for (uint8 i = 0; i < TEAM_COUNT; ++i) {
            alive[i] = true;
        }

        // Same self-check BaseHook performs: deployed address must encode our flags.
        Hooks.validateHookPermissions(IHooks(address(this)), getHookPermissions());
    }

    /// @notice Hook permission table; must match the mined deployment address.
    function getHookPermissions() public pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ---------------------------------------------------------------------
    // Fan actions
    // ---------------------------------------------------------------------

    /// @notice Pledge to a team. One-time and irreversible: pick your nation
    /// like you mean it. Only teams still in the tournament accept new fans.
    function joinTeam(uint8 team) external {
        if (team >= TEAM_COUNT) revert InvalidTeam();
        if (_fanTeamPlusOne[msg.sender] != 0) revert AlreadyJoined();
        _sync();
        if (currentMatch == MATCH_COUNT) revert TournamentOver();
        if (!alive[team]) revert TeamEliminated();
        _fanTeamPlusOne[msg.sender] = team + 1;
        emit FanJoined(msg.sender, team);
    }

    /// @notice Settle any matches that are due. Callable by anyone; also runs
    /// automatically before every swap. The tournament can never get stuck.
    function poke() external {
        _sync();
    }

    /// @notice Claim your share of the Champions Pot. Champion-team fans only,
    /// pro rata to caps earned over the whole tournament.
    function claim() external {
        if (champion == TBD) revert TournamentNotOver();
        if (block.timestamp > finalizedAt + CLAIM_WINDOW) revert ClaimWindowClosed();
        uint8 teamPlusOne = _fanTeamPlusOne[msg.sender];
        if (teamPlusOne == 0 || teamPlusOne - 1 != champion) revert NotAFanOfChampion();
        if (claimed[msg.sender]) revert AlreadyClaimed();
        uint256 fanCaps = caps[msg.sender];
        uint256 total = teamCaps[champion];
        if (fanCaps == 0 || total == 0) revert NothingToClaim();

        uint256 amount0 = pot0 * fanCaps / total;
        uint256 amount1 = pot1 * fanCaps / total;

        // Effects before interactions.
        claimed[msg.sender] = true;

        if (amount0 > 0) _transfer(poolKey.currency0, msg.sender, amount0);
        if (amount1 > 0) _transfer(poolKey.currency1, msg.sender, amount1);
        emit PotClaimed(msg.sender, amount0, amount1);
    }

    /// @notice After the claim window (or immediately, if the champion has no
    /// caps to distribute to), donate whatever remains in the pot to the
    /// pool's in-range LPs. Anyone can call. The deployer never touches it.
    function sweepToLPs() external {
        if (champion == TBD) revert TournamentNotOver();
        bool championUnclaimable = teamCaps[champion] == 0;
        if (!championUnclaimable && block.timestamp <= finalizedAt + CLAIM_WINDOW) {
            revert ClaimWindowOpen();
        }
        uint256 amount0 = _heldBalance(poolKey.currency0);
        uint256 amount1 = _heldBalance(poolKey.currency1);
        if (amount0 == 0 && amount1 == 0) revert NothingToClaim();
        poolManager.unlock(abi.encode(amount0, amount1));
        emit PotDonatedToLPs(amount0, amount1);
    }

    /// @inheritdoc IUnlockCallback
    /// @dev Only reachable from `sweepToLPs` via the PoolManager.
    function unlockCallback(bytes calldata data) external onlyPoolManager returns (bytes memory) {
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));
        poolManager.donate(poolKey, amount0, amount1, "");
        if (amount0 > 0) _settleCurrency(poolKey.currency0, amount0);
        if (amount1 > 0) _settleCurrency(poolKey.currency1, amount1);
        return "";
    }

    // ---------------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------------

    /// @notice Team a fan pledged to. Reverts if the fan never pledged.
    function fanTeam(address fan) external view returns (uint8) {
        uint8 teamPlusOne = _fanTeamPlusOne[fan];
        if (teamPlusOne == 0) revert InvalidTeam();
        return teamPlusOne - 1;
    }

    function hasJoined(address fan) external view returns (bool) {
        return _fanTeamPlusOne[fan] != 0;
    }

    function getMatch(uint8 matchId) external view returns (Match memory) {
        return _matches[matchId];
    }

    /// @notice Goals currently on the board for one side of a match.
    function goalsOf(uint8 matchId, bool sideA) public view returns (uint64) {
        Match storage m = _matches[matchId];
        uint256 volume = sideA ? m.volumeA : m.volumeB;
        return uint64(volume / goalThreshold);
    }

    /// @notice Slot timing for a match: [start, regulation end, extra-time end).
    function matchTimes(uint8 matchId) public view returns (uint64 start, uint64 regEnd, uint64 etEnd) {
        uint64 slot = regulation + extraTime + breakTime;
        start = kickoff + uint64(matchId) * slot;
        regEnd = start + regulation;
        etEnd = regEnd + extraTime;
    }

    /// @notice The LP fee (pips) a given swapper would pay right now.
    function feeFor(address swapper) public view returns (uint24) {
        if (currentMatch == MATCH_COUNT) return FEE_NEUTRAL;
        uint8 teamPlusOne = _fanTeamPlusOne[swapper];
        if (teamPlusOne == 0) return FEE_NEUTRAL;
        uint8 team = teamPlusOne - 1;
        if (!alive[team]) return FEE_NEUTRAL;

        (uint64 start, uint64 regEnd, uint64 etEnd) = matchTimes(currentMatch);
        Match storage m = _matches[currentMatch];
        bool playing = (m.teamA == team || m.teamB == team) && block.timestamp >= start && block.timestamp < etEnd;
        if (!playing) return FEE_FAN_ALIVE;
        if (block.timestamp >= regEnd) return FEE_GOLDEN_GOAL; // sudden death, tied by construction
        return FEE_MATCH_LIVE;
    }

    // ---------------------------------------------------------------------
    // Hook callbacks
    // ---------------------------------------------------------------------

    /// @dev Binds this hook to exactly one dynamic-fee pool, forever.
    function afterInitialize(address, PoolKey calldata key, uint160, int24)
        external
        onlyPoolManager
        returns (bytes4)
    {
        if (poolBound) revert AlreadyInitialized();
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        poolKey = key;
        poolBound = true;
        return IHooks.afterInitialize.selector;
    }

    /// @dev Settles due matches, then quotes the swapper's fee tier.
    /// `tx.origin` attribution is game-state only; see contract NatSpec.
    function beforeSwap(address, PoolKey calldata key, SwapParams calldata, bytes calldata)
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        _checkPool(key);
        _sync();
        uint24 fee = feeFor(tx.origin);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    /// @dev Records shots/goals/caps for pledged fans and skims the Champions
    /// Pot from the unspecified side of the swap. May settle the current match
    /// instantly on a golden goal.
    function afterSwap(address, PoolKey calldata key, SwapParams calldata params, BalanceDelta delta, bytes calldata)
        external
        onlyPoolManager
        returns (bytes4, int128)
    {
        _checkPool(key);

        uint8 teamPlusOne = _fanTeamPlusOne[tx.origin];
        if (teamPlusOne == 0 || currentMatch == MATCH_COUNT) {
            return (IHooks.afterSwap.selector, 0); // neutral swap: no skim, no shots
        }
        uint8 team = teamPlusOne - 1;
        if (!alive[team]) return (IHooks.afterSwap.selector, 0);

        // Volume metric: the currency1 leg of the swap, direction-agnostic.
        int128 amt1 = delta.amount1();
        uint256 volume = uint256(uint128(amt1 < 0 ? -amt1 : amt1));
        if (volume > 0) {
            caps[tx.origin] += volume;
            teamCaps[team] += volume;
        }
        _recordShot(team, volume);

        // Champions Pot skim in the unspecified currency (cf. v4 FeeTakingHook).
        bool specifiedIs0 = (params.amountSpecified < 0) == params.zeroForOne;
        (Currency skimCurrency, int128 unspecified) =
            specifiedIs0 ? (key.currency1, delta.amount1()) : (key.currency0, delta.amount0());
        if (unspecified < 0) unspecified = -unspecified;
        uint256 skim = uint256(uint128(unspecified)) * SKIM_BIPS / BIPS_DENOMINATOR;
        if (skim > 0) {
            poolManager.take(skimCurrency, address(this), skim);
            if (Currency.unwrap(skimCurrency) == Currency.unwrap(key.currency0)) pot0 += skim;
            else pot1 += skim;
        }
        return (IHooks.afterSwap.selector, skim.toInt128());
    }

    // ---------------------------------------------------------------------
    // Internal game engine
    // ---------------------------------------------------------------------

    /// @dev Counts a fan swap toward the live match, if their team is playing.
    /// Emits goals and performs golden-goal sudden-death settlement.
    function _recordShot(uint8 team, uint256 volume) internal {
        uint8 matchId = currentMatch;
        Match storage m = _matches[matchId];
        if (m.teamA != team && m.teamB != team) return;

        (uint64 start, uint64 regEnd, uint64 etEnd) = matchTimes(matchId);
        if (block.timestamp < start || block.timestamp >= etEnd) return;
        bool inExtraTime = block.timestamp >= regEnd; // only reachable while tied (else _sync settled it)

        bool isA = m.teamA == team;
        uint64 goalsBefore = goalsOf(matchId, isA);
        if (isA) {
            m.shotsA += 1;
            // forge-lint: disable-next-line(unsafe-typecast)
            m.volumeA += uint128(volume); // safe: volume = abs(int128) <= type(uint128).max
        } else {
            m.shotsB += 1;
            // forge-lint: disable-next-line(unsafe-typecast)
            m.volumeB += uint128(volume); // safe: volume = abs(int128) <= type(uint128).max
        }
        emit ShotTaken(tx.origin, team, matchId, volume);

        uint64 goalsAfter = goalsOf(matchId, isA);
        if (goalsAfter > goalsBefore) {
            emit GoalScored(team, matchId, goalsAfter);
            if (inExtraTime) {
                // Golden goal: first strike in sudden death ends the match now.
                _settleMatch(matchId, team, isA ? m.teamB : m.teamA, Tiebreak.GoldenGoal);
            }
        }
    }

    /// @dev Settles every match whose result is decidable at this timestamp.
    /// Bounded loop (<= 7 iterations over the hook's whole life).
    function _sync() internal {
        while (currentMatch < MATCH_COUNT) {
            uint8 matchId = currentMatch;
            Match storage m = _matches[matchId];
            (, uint64 regEnd, uint64 etEnd) = matchTimes(matchId);
            if (block.timestamp < regEnd) break; // match still in regulation

            uint64 goalsA = goalsOf(matchId, true);
            uint64 goalsB = goalsOf(matchId, false);

            if (goalsA != goalsB) {
                // Full-time result stands the moment regulation ends.
                (uint8 winner, uint8 loser) = goalsA > goalsB ? (m.teamA, m.teamB) : (m.teamB, m.teamA);
                _settleMatch(matchId, winner, loser, Tiebreak.None);
                continue;
            }
            if (block.timestamp < etEnd) break; // sudden death in progress; a golden goal will settle it

            // Extra time expired still level: penalties (shots), then seed.
            if (m.shotsA != m.shotsB) {
                (uint8 winner, uint8 loser) = m.shotsA > m.shotsB ? (m.teamA, m.teamB) : (m.teamB, m.teamA);
                _settleMatch(matchId, winner, loser, Tiebreak.Penalties);
            } else {
                (uint8 winner, uint8 loser) = m.teamA < m.teamB ? (m.teamA, m.teamB) : (m.teamB, m.teamA);
                _settleMatch(matchId, winner, loser, Tiebreak.Seed);
            }
        }
    }

    /// @dev Marks a match settled, eliminates the loser, feeds the bracket,
    /// and crowns the champion after the final.
    function _settleMatch(uint8 matchId, uint8 winner, uint8 loser, Tiebreak tiebreak) internal {
        Match storage m = _matches[matchId];
        m.settled = true;
        m.winner = winner;
        alive[loser] = false;

        (uint64 goalsW, uint64 goalsL) = m.teamA == winner
            ? (goalsOf(matchId, true), goalsOf(matchId, false))
            : (goalsOf(matchId, false), goalsOf(matchId, true));
        emit MatchSettled(matchId, winner, loser, goalsW, goalsL, tiebreak);

        if (matchId < 4) {
            // QF winners feed SFs: m0,m1 -> m4; m2,m3 -> m5.
            Match storage next = _matches[4 + matchId / 2];
            if (matchId % 2 == 0) next.teamA = winner;
            else next.teamB = winner;
        } else if (matchId < 6) {
            // SF winners feed the final.
            Match storage finalMatch = _matches[6];
            if (matchId == 4) finalMatch.teamA = winner;
            else finalMatch.teamB = winner;
        } else {
            champion = winner;
            finalizedAt = uint64(block.timestamp);
            emit ChampionCrowned(winner, pot0, pot1);
        }
        currentMatch = matchId + 1;
    }

    // ---------------------------------------------------------------------
    // Internal plumbing
    // ---------------------------------------------------------------------

    function _checkPool(PoolKey calldata key) internal view {
        if (!poolBound) revert NotInitialized();
        if (PoolId.unwrap(key.toId()) != PoolId.unwrap(poolKey.toId())) revert WrongPool();
    }

    function _heldBalance(Currency currency) internal view returns (uint256) {
        return currency.balanceOfSelf();
    }

    function _transfer(Currency currency, address to, uint256 amount) internal {
        currency.transfer(to, amount);
    }

    /// @dev Pays a donation debt to the PoolManager (ERC20 or native).
    function _settleCurrency(Currency currency, uint256 amount) internal {
        if (currency.isAddressZero()) {
            poolManager.settle{value: amount}();
        } else {
            poolManager.sync(currency);
            currency.transfer(address(poolManager), amount);
            poolManager.settle();
        }
    }

    /// @dev The pot can hold native currency (e.g. an OKB-paired pool).
    receive() external payable {}

    // ---------------------------------------------------------------------
    // Unused hook callbacks (flags are off; PoolManager never calls these)
    // ---------------------------------------------------------------------

    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}
