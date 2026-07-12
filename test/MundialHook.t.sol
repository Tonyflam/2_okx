// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {MundialHook} from "../src/MundialHook.sol";
import {MundialToken} from "../src/MundialToken.sol";

contract MundialHookTest is Test, Deployers {
    MundialHook hook;

    // Deterministic address with exactly our flag bits set.
    address constant HOOK_ADDRESS = address(
        uint160(
            Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        )
    );

    uint64 constant REGULATION = 1 hours;
    uint64 constant EXTRA_TIME = 15 minutes;
    uint64 constant BREAK_TIME = 5 minutes;
    uint64 constant SLOT = REGULATION + EXTRA_TIME + BREAK_TIME;
    uint256 constant GOAL_THRESHOLD = 0.5e18; // 0.5 currency1 per goal

    uint64 kickoff;

    address fanARG = makeAddr("fanARG"); // team 0
    address fanFRA = makeAddr("fanFRA"); // team 1
    address fanBRA = makeAddr("fanBRA"); // team 2
    address neutral = makeAddr("neutral");

    bytes32[8] TEAMS = [
        bytes32("Argentina"),
        bytes32("France"),
        bytes32("Brazil"),
        bytes32("England"),
        bytes32("Spain"),
        bytes32("Germany"),
        bytes32("Portugal"),
        bytes32("Netherlands")
    ];

    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        kickoff = uint64(block.timestamp + 10 minutes);
        deployCodeTo(
            "MundialHook.sol:MundialHook",
            abi.encode(manager, TEAMS, kickoff, REGULATION, EXTRA_TIME, BREAK_TIME, GOAL_THRESHOLD),
            HOOK_ADDRESS
        );
        hook = MundialHook(payable(HOOK_ADDRESS));

        (key,) = initPool(currency0, currency1, IHooks(HOOK_ADDRESS), LPFeeLibrary.DYNAMIC_FEE_FLAG, SQRT_PRICE_1_1);
        // Deep, wide liquidity so match-sized swaps have negligible price impact.
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({tickLower: -6000, tickUpper: 6000, liquidityDelta: 5_000_000e18, salt: 0}),
            ZERO_BYTES
        );

        // Give the actors funds and router approvals.
        address[4] memory actors = [fanARG, fanFRA, fanBRA, neutral];
        for (uint256 i = 0; i < actors.length; i++) {
            MockERC20(Currency.unwrap(currency0)).transfer(actors[i], 1_000e18);
            MockERC20(Currency.unwrap(currency1)).transfer(actors[i], 1_000e18);
            vm.startPrank(actors[i]);
            MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
            MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
            vm.stopPrank();
        }
    }

    // -----------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------

    /// @dev Swap as `who` (msg.sender AND tx.origin), exact-in.
    function _swap(address who, bool zeroForOne, uint256 amountIn) internal returns (BalanceDelta delta) {
        vm.prank(who, who);
        delta = swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: -int256(amountIn),
                sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );
    }

    function _warpToMatch(uint8 matchId) internal {
        (uint64 start,,) = hook.matchTimes(matchId);
        vm.warp(start + 1);
    }

    function _warpToExtraTime(uint8 matchId) internal {
        (, uint64 regEnd,) = hook.matchTimes(matchId);
        vm.warp(regEnd + 1);
    }

    function _warpPastSlot(uint8 matchId) internal {
        (,, uint64 etEnd) = hook.matchTimes(matchId);
        vm.warp(etEnd + 1);
    }

    // -----------------------------------------------------------------
    // Deployment / permissions / binding
    // -----------------------------------------------------------------

    function test_hookPermissionsMatchAddress() public view {
        Hooks.Permissions memory p = hook.getHookPermissions();
        assertTrue(p.afterInitialize && p.beforeSwap && p.afterSwap && p.afterSwapReturnDelta);
        assertTrue(Hooks.isValidHookAddress(IHooks(address(hook)), LPFeeLibrary.DYNAMIC_FEE_FLAG));
    }

    function test_constructor_revertsOnBadSchedule() public {
        vm.expectRevert(MundialHook.InvalidSchedule.selector);
        deployCodeTo(
            "MundialHook.sol:MundialHook",
            abi.encode(manager, TEAMS, kickoff, uint64(0), EXTRA_TIME, BREAK_TIME, GOAL_THRESHOLD),
            address(uint160(HOOK_ADDRESS) + 0x10000)
        );
    }

    function test_constructor_revertsOnZeroThreshold() public {
        vm.expectRevert(MundialHook.InvalidThreshold.selector);
        deployCodeTo(
            "MundialHook.sol:MundialHook",
            abi.encode(manager, TEAMS, kickoff, REGULATION, EXTRA_TIME, BREAK_TIME, uint256(0)),
            address(uint160(HOOK_ADDRESS) + 0x20000)
        );
    }

    function test_initialize_rejectsStaticFeePool() public {
        vm.expectRevert(); // wrapped MustUseDynamicFee
        initPool(currency0, currency1, IHooks(address(hook)), 3000, SQRT_PRICE_1_1);
    }

    function test_initialize_rejectsSecondPool() public {
        // A second dynamic-fee pool (different tick spacing) must be rejected.
        PoolKey memory second = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 30,
            hooks: IHooks(address(hook))
        });
        vm.expectRevert(); // wrapped AlreadyInitialized
        manager.initialize(second, SQRT_PRICE_1_1);
    }

    function test_callbacks_onlyPoolManager() public {
        vm.expectRevert(MundialHook.NotPoolManager.selector);
        hook.afterInitialize(address(this), key, SQRT_PRICE_1_1, 0);
        vm.expectRevert(MundialHook.NotPoolManager.selector);
        hook.beforeSwap(address(this), key, SwapParams(true, -1, 0), "");
        vm.expectRevert(MundialHook.NotPoolManager.selector);
        hook.afterSwap(address(this), key, SwapParams(true, -1, 0), BalanceDelta.wrap(0), "");
        vm.expectRevert(MundialHook.NotPoolManager.selector);
        hook.unlockCallback("");
    }

    // -----------------------------------------------------------------
    // joinTeam
    // -----------------------------------------------------------------

    function test_joinTeam() public {
        vm.expectEmit(true, true, false, false);
        emit MundialHook.FanJoined(fanARG, 0);
        vm.prank(fanARG);
        hook.joinTeam(0);
        assertEq(hook.fanTeam(fanARG), 0);
        assertTrue(hook.hasJoined(fanARG));
    }

    function test_joinTeam_revertsTwice() public {
        vm.startPrank(fanARG);
        hook.joinTeam(0);
        vm.expectRevert(MundialHook.AlreadyJoined.selector);
        hook.joinTeam(1);
        vm.stopPrank();
    }

    function test_joinTeam_revertsInvalidTeam() public {
        vm.expectRevert(MundialHook.InvalidTeam.selector);
        hook.joinTeam(8);
    }

    function test_joinTeam_revertsEliminatedTeam() public {
        // Nobody swaps; push past match 0 so team 1 (higher seed) is eliminated by seed rule.
        _warpPastSlot(0);
        hook.poke();
        assertFalse(hook.alive(1));
        vm.expectRevert(MundialHook.TeamEliminated.selector);
        vm.prank(fanFRA);
        hook.joinTeam(1);
    }

    // -----------------------------------------------------------------
    // Fee tiers
    // -----------------------------------------------------------------

    function test_fees_tiersByState() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanBRA);
        hook.joinTeam(2);

        // Before kickoff: fan alive, not playing.
        assertEq(hook.feeFor(neutral), hook.FEE_NEUTRAL());
        assertEq(hook.feeFor(fanARG), hook.FEE_FAN_ALIVE());

        // Match 0 live: ARG plays, BRA does not.
        _warpToMatch(0);
        assertEq(hook.feeFor(fanARG), hook.FEE_MATCH_LIVE());
        assertEq(hook.feeFor(fanBRA), hook.FEE_FAN_ALIVE());
        assertEq(hook.feeFor(neutral), hook.FEE_NEUTRAL());

        // Extra time (nobody scored: tied 0-0).
        _warpToExtraTime(0);
        assertEq(hook.feeFor(fanARG), hook.FEE_GOLDEN_GOAL());
    }

    function test_fees_fanPaysLessThanNeutral() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);

        uint256 snap = vm.snapshotState();
        BalanceDelta fanDelta = _swap(fanARG, true, 1e18);
        int128 fanOut = fanDelta.amount1();
        vm.revertToState(snap);
        BalanceDelta neutralDelta = _swap(neutral, true, 1e18);
        int128 neutralOut = neutralDelta.amount1();

        // Fan pays 0.15% LP fee vs 0.50% but also a 0.20% pot skim.
        // Net: fan output must still beat neutral output.
        assertGt(fanOut, neutralOut, "fan swap should net more than neutral");
    }

    function test_fees_eliminatedFanPaysNeutral() public {
        vm.prank(fanFRA);
        hook.joinTeam(1);
        _warpPastSlot(0); // FRA (seed 1) eliminated by seed tiebreak
        hook.poke();
        assertEq(hook.feeFor(fanFRA), hook.FEE_NEUTRAL());
    }

    // -----------------------------------------------------------------
    // Scoring: shots, goals, caps
    // -----------------------------------------------------------------

    function test_scoring_fanSwapDuringMatch() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);

        BalanceDelta delta = _swap(fanARG, true, 1e18);
        uint256 userOut = uint256(uint128(delta.amount1()));
        // volumeA records the gross currency1 leg: user output + pot skim.
        uint256 gross = userOut + hook.pot1();

        MundialHook.Match memory m = hook.getMatch(0);
        assertEq(m.shotsA, 1);
        assertEq(uint256(m.volumeA), gross);
        assertEq(hook.caps(fanARG), gross);
        assertEq(hook.teamCaps(0), gross);
        // ~1e18 in at 1:1 price crosses the 0.5e18 goal threshold.
        assertGe(hook.goalsOf(0, true), 1);
    }

    function test_scoring_neutralSwapDoesNothing() public {
        _warpToMatch(0);
        _swap(neutral, true, 1e18);
        MundialHook.Match memory m = hook.getMatch(0);
        assertEq(m.shotsA + m.shotsB, 0);
        assertEq(hook.pot0() + hook.pot1(), 0);
    }

    function test_scoring_nonPlayingFanEarnsCapsOnly() public {
        vm.prank(fanBRA);
        hook.joinTeam(2); // BRA plays match 1, not match 0
        _warpToMatch(0);
        _swap(fanBRA, true, 1e18);
        MundialHook.Match memory m0 = hook.getMatch(0);
        MundialHook.Match memory m1 = hook.getMatch(1);
        assertEq(m0.shotsA + m0.shotsB + m1.shotsA + m1.shotsB, 0);
        assertGt(hook.caps(fanBRA), 0);
    }

    // -----------------------------------------------------------------
    // Champions Pot skim
    // -----------------------------------------------------------------

    function test_skim_accruesToPot() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        BalanceDelta delta = _swap(fanARG, true, 1e18); // exact-in 0->1: skim on currency1 output
        uint256 out = uint256(uint128(delta.amount1()));
        // delta.amount1() is what the swapper received net of the skim;
        // gross output G satisfies: skim = G * 20 / 10000, out = G - skim.
        uint256 gross = out * 10000 / (10000 - 20);
        assertApproxEqAbs(hook.pot1(), gross - out, 2);
        assertEq(hook.pot0(), 0);
        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), hook.pot1());
    }

    function test_skim_bothDirectionsFillBothPots() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, 1e18);
        _swap(fanARG, false, 1e18);
        assertGt(hook.pot0(), 0);
        assertGt(hook.pot1(), 0);
    }

    // -----------------------------------------------------------------
    // Match settlement & bracket
    // -----------------------------------------------------------------

    function test_settle_regulationWinAdvancesBracket() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, 2e18); // ARG scores, FRA doesn't

        _warpToExtraTime(0); // regulation over, ARG ahead
        vm.expectEmit(true, true, false, false);
        emit MundialHook.MatchSettled(0, 0, 1, 0, 0, MundialHook.Tiebreak.None);
        hook.poke();

        assertEq(hook.currentMatch(), 1);
        assertFalse(hook.alive(1));
        assertEq(hook.getMatch(4).teamA, 0); // ARG into SF1
    }

    function test_settle_goldenGoalWinsInstantly() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToExtraTime(0); // 0-0 after regulation -> sudden death

        vm.expectEmit(true, true, false, false);
        emit MundialHook.MatchSettled(0, 0, 1, 0, 0, MundialHook.Tiebreak.GoldenGoal);
        _swap(fanARG, true, 1e18); // first goal in ET settles in the same tx

        assertEq(hook.currentMatch(), 1);
        assertTrue(hook.getMatch(0).settled);
        assertEq(hook.getMatch(0).winner, 0);
    }

    function test_settle_penaltiesByShots() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanFRA);
        hook.joinTeam(1);
        _warpToMatch(0);
        // Both score 0 goals (below threshold) but ARG takes 2 shots vs 1.
        _swap(fanARG, true, 0.1e18);
        _swap(fanARG, true, 0.1e18);
        _swap(fanFRA, true, 0.1e18);

        _warpPastSlot(0);
        vm.expectEmit(true, true, false, false);
        emit MundialHook.MatchSettled(0, 0, 1, 0, 0, MundialHook.Tiebreak.Penalties);
        hook.poke();
    }

    function test_settle_seedTiebreakOnDeadlock() public {
        _warpPastSlot(0); // no activity at all
        vm.expectEmit(true, true, false, false);
        emit MundialHook.MatchSettled(0, 0, 1, 0, 0, MundialHook.Tiebreak.Seed);
        hook.poke();
    }

    function test_settle_fullTournamentByPoke() public {
        _warpPastSlot(6);
        hook.poke();
        assertEq(hook.currentMatch(), hook.MATCH_COUNT());
        // All-seed tiebreaks: 0 beats 1, 2 beats 3, ... then 0 beats 2, 4 beats 6, then 0 beats 4.
        assertEq(hook.champion(), 0);
        assertGt(hook.finalizedAt(), 0);
    }

    function test_settle_lazySettlementOnSwap() public {
        _warpPastSlot(0);
        _swap(neutral, true, 0.1e18); // the swap itself settles match 0
        assertTrue(hook.getMatch(0).settled);
    }

    // -----------------------------------------------------------------
    // Claims
    // -----------------------------------------------------------------

    function _runTournamentWithChampionARG() internal {
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, 2e18); // fills pot1 + wins m0
        _swap(fanARG, false, 1e18); // fills pot0
        _warpPastSlot(6);
        hook.poke(); // ARG wins everything else by seed
        assertEq(hook.champion(), 0);
    }

    function test_claim_championFanGetsPot() public {
        _runTournamentWithChampionARG();
        uint256 pot0 = hook.pot0();
        uint256 pot1 = hook.pot1();
        assertGt(pot1, 0);

        uint256 bal0Before = MockERC20(Currency.unwrap(currency0)).balanceOf(fanARG);
        uint256 bal1Before = MockERC20(Currency.unwrap(currency1)).balanceOf(fanARG);

        vm.prank(fanARG);
        hook.claim();

        // Sole champion fan: gets 100% of both pots.
        assertEq(MockERC20(Currency.unwrap(currency0)).balanceOf(fanARG) - bal0Before, pot0);
        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(fanARG) - bal1Before, pot1);
    }

    function test_claim_proRataBetweenFans() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanBRA);
        hook.joinTeam(0); // second ARG fan (address name notwithstanding)
        _warpToMatch(0);
        _swap(fanARG, true, 3e18);
        _swap(fanBRA, true, 1e18);
        _warpPastSlot(6);
        hook.poke();

        uint256 pot1 = hook.pot1();
        uint256 capsA = hook.caps(fanARG);
        uint256 capsB = hook.caps(fanBRA);
        uint256 total = hook.teamCaps(0);
        assertEq(capsA + capsB, total);

        uint256 balBefore = MockERC20(Currency.unwrap(currency1)).balanceOf(fanARG);
        vm.prank(fanARG);
        hook.claim();
        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(fanARG) - balBefore, pot1 * capsA / total);

        balBefore = MockERC20(Currency.unwrap(currency1)).balanceOf(fanBRA);
        vm.prank(fanBRA);
        hook.claim();
        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(fanBRA) - balBefore, pot1 * capsB / total);

        // Hook keeps only rounding dust.
        assertLe(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), 1);
    }

    function test_claim_revertsBeforeFinal() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.expectRevert(MundialHook.TournamentNotOver.selector);
        vm.prank(fanARG);
        hook.claim();
    }

    function test_claim_revertsForNonChampionFan() public {
        vm.prank(fanFRA);
        hook.joinTeam(1);
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanFRA, true, 0.1e18); // FRA takes a shot but scores no goal
        _swap(fanARG, true, 2e18); // ARG scores and wins match 0
        _runTournamentEnd();
        assertEq(hook.champion(), 0);
        vm.expectRevert(MundialHook.NotAFanOfChampion.selector);
        vm.prank(fanFRA);
        hook.claim();
    }

    function test_claim_revertsOnDoubleClaim() public {
        _runTournamentWithChampionARG();
        vm.startPrank(fanARG);
        hook.claim();
        vm.expectRevert(MundialHook.AlreadyClaimed.selector);
        hook.claim();
        vm.stopPrank();
    }

    function test_claim_revertsAfterWindow() public {
        _runTournamentWithChampionARG();
        vm.warp(hook.finalizedAt() + hook.CLAIM_WINDOW() + 1);
        vm.expectRevert(MundialHook.ClaimWindowClosed.selector);
        vm.prank(fanARG);
        hook.claim();
    }

    function test_claim_revertsWithZeroCaps() public {
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanBRA);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, 1e18); // only fanARG has caps
        _runTournamentEnd();
        vm.expectRevert(MundialHook.NothingToClaim.selector);
        vm.prank(fanBRA);
        hook.claim();
    }

    function _runTournamentEnd() internal {
        _warpPastSlot(6);
        hook.poke();
    }

    // -----------------------------------------------------------------
    // Sweep to LPs
    // -----------------------------------------------------------------

    function test_sweep_revertsDuringClaimWindow() public {
        _runTournamentWithChampionARG();
        vm.expectRevert(MundialHook.ClaimWindowOpen.selector);
        hook.sweepToLPs();
    }

    function test_sweep_donatesLeftoversAfterWindow() public {
        _runTournamentWithChampionARG();
        uint256 pot1 = hook.pot1();
        assertGt(pot1, 0);
        vm.warp(hook.finalizedAt() + hook.CLAIM_WINDOW() + 1);

        vm.expectEmit(false, false, false, false);
        emit MundialHook.PotDonatedToLPs(0, 0);
        hook.sweepToLPs();

        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), 0);
        assertEq(MockERC20(Currency.unwrap(currency0)).balanceOf(address(hook)), 0);
    }

    function test_sweep_zeroCapsChampion() public {
        // A fan of a NON-champion team fills the pot (alive fans skim even when
        // not playing), but the seed rule crowns team 0, which has zero caps.
        vm.prank(fanBRA);
        hook.joinTeam(2);
        _warpToMatch(0); // BRA is alive but not playing: caps + skim, no shots
        _swap(fanBRA, true, 1e18);
        _warpPastSlot(6);
        hook.poke();
        assertEq(hook.champion(), 0); // BRA loses SF to ARG on seed
        assertEq(hook.teamCaps(0), 0);
        assertGt(hook.pot1(), 0);

        // Champion has no caps: sweep allowed immediately.
        hook.sweepToLPs();
        assertEq(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), 0);
    }

    // -----------------------------------------------------------------
    // Fuzz
    // -----------------------------------------------------------------

    /// @dev Goals are exactly volume / threshold, monotone in volume.
    function testFuzz_goalMath(uint96 amountIn) public {
        amountIn = uint96(bound(uint256(amountIn), 0.01e18, 50e18));
        vm.prank(fanARG);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, amountIn);
        MundialHook.Match memory m = hook.getMatch(0);
        assertEq(hook.goalsOf(0, true), uint64(uint256(m.volumeA) / GOAL_THRESHOLD));
    }

    /// @dev Total claims never exceed the pot (conservation).
    function testFuzz_claimConservation(uint96 a, uint96 b) public {
        a = uint96(bound(uint256(a), 0.01e18, 20e18));
        b = uint96(bound(uint256(b), 0.01e18, 20e18));
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanBRA);
        hook.joinTeam(0);
        _warpToMatch(0);
        _swap(fanARG, true, a);
        _swap(fanBRA, true, b);
        _warpPastSlot(6);
        hook.poke();

        uint256 pot0 = hook.pot0();
        uint256 pot1 = hook.pot1();
        vm.prank(fanARG);
        hook.claim();
        vm.prank(fanBRA);
        hook.claim();

        // Hook never sends out more than it holds; leftover is only dust.
        assertLe(MockERC20(Currency.unwrap(currency0)).balanceOf(address(hook)), pot0);
        assertLe(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), pot1);
        assertLe(MockERC20(Currency.unwrap(currency1)).balanceOf(address(hook)), 2); // dust bound for 2 claimants
    }

    /// @dev The tournament always terminates and crowns a champion under
    /// arbitrary time jumps and pokes.
    function testFuzz_tournamentAlwaysTerminates(uint32 jump1, uint32 jump2) public {
        vm.warp(uint256(kickoff) + uint256(jump1));
        hook.poke();
        vm.warp(uint256(kickoff) + uint256(jump1) + uint256(jump2) + 7 * uint256(SLOT));
        hook.poke();
        assertEq(hook.currentMatch(), hook.MATCH_COUNT());
        assertLt(hook.champion(), 8);
    }

    // -----------------------------------------------------------------
    // Token
    // -----------------------------------------------------------------

    function test_token_fixedSupply() public {
        MundialToken token = new MundialToken(address(0xBEEF), 100_000_000e18);
        assertEq(token.totalSupply(), 100_000_000e18);
        assertEq(token.balanceOf(address(0xBEEF)), 100_000_000e18);
        assertEq(token.decimals(), 18);
    }
}
