// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {HookMiner} from "v4-periphery/test/shared/HookMiner.sol";

import {MundialHook} from "../src/MundialHook.sol";
import {MundialToken} from "../src/MundialToken.sol";

/// @notice Deploys $MUNDIAL, mines + deploys MundialHook, and initializes the
/// MUNDIAL/<quote> dynamic-fee pool on Uniswap v4 (X Layer).
///
/// Environment:
///   PRIVATE_KEY        deployer key (never commit)
///   POOL_MANAGER       0x360e68faccca8ca495c1b759fd9eee466db9fb32 on X Layer (196)
///   QUOTE_TOKEN        e.g. WOKB or USDT address on X Layer; address(0) = native OKB
///   KICKOFF            unix ts of match 0 (default: now + 1 hour)
///   REGULATION         seconds (default 8 hours)
///   EXTRA_TIME         seconds (default 1 hour)
///   BREAK_TIME         seconds (default 3 hours)
///   GOAL_THRESHOLD     quote-side volume per goal in wei (default 1e18)
///
/// Usage:
///   forge script script/DeployMundial.s.sol --rpc-url $XLAYER_RPC_URL --broadcast -vvvv
contract DeployMundial is Script {
    /// @dev Deterministic CREATE2 proxy (Arachnid), predeployed on OP-stack chains.
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    uint256 constant TOKEN_SUPPLY = 100_000_000e18;

    struct Config {
        IPoolManager poolManager;
        address quote;
        uint64 kickoff;
        uint64 regulation;
        uint64 extraTime;
        uint64 breakTime;
        uint256 goalThreshold;
    }

    function _teams() internal pure returns (bytes32[8] memory teams) {
        teams = [
            bytes32("Argentina"),
            bytes32("France"),
            bytes32("Brazil"),
            bytes32("England"),
            bytes32("Spain"),
            bytes32("Germany"),
            bytes32("Portugal"),
            bytes32("Netherlands")
        ];
    }

    function _config() internal view returns (Config memory cfg) {
        cfg = Config({
            poolManager: IPoolManager(vm.envAddress("POOL_MANAGER")),
            quote: vm.envOr("QUOTE_TOKEN", address(0)),
            kickoff: uint64(vm.envOr("KICKOFF", block.timestamp + 1 hours)),
            regulation: uint64(vm.envOr("REGULATION", uint256(8 hours))),
            extraTime: uint64(vm.envOr("EXTRA_TIME", uint256(1 hours))),
            breakTime: uint64(vm.envOr("BREAK_TIME", uint256(3 hours))),
            goalThreshold: vm.envOr("GOAL_THRESHOLD", uint256(1e18))
        });
    }

    function _deployHook(Config memory cfg) internal returns (MundialHook hook) {
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );
        bytes memory constructorArgs = abi.encode(
            cfg.poolManager, _teams(), cfg.kickoff, cfg.regulation, cfg.extraTime, cfg.breakTime, cfg.goalThreshold
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(MundialHook).creationCode, constructorArgs);
        hook = new MundialHook{salt: salt}(
            cfg.poolManager, _teams(), cfg.kickoff, cfg.regulation, cfg.extraTime, cfg.breakTime, cfg.goalThreshold
        );
        require(address(hook) == hookAddress, "hook address mismatch");
    }

    function _initPool(Config memory cfg, address token, address hook) internal returns (PoolKey memory key) {
        (Currency c0, Currency c1) = token < cfg.quote
            ? (Currency.wrap(token), Currency.wrap(cfg.quote))
            : (Currency.wrap(cfg.quote), Currency.wrap(token));
        key = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        // Starting price 1:1; adjust SQRT_PRICE for the real pairing before broadcast.
        cfg.poolManager.initialize(key, 79228162514264337593543950336);
    }

    function run() external {
        Config memory cfg = _config();
        require(CREATE2_DEPLOYER.code.length > 0, "CREATE2 deployer proxy missing on this chain");

        vm.startBroadcast();
        MundialToken token = new MundialToken(msg.sender, TOKEN_SUPPLY);
        MundialHook hook = _deployHook(cfg);
        PoolKey memory key = _initPool(cfg, address(token), address(hook));
        vm.stopBroadcast();

        console2.log("MundialToken:", address(token));
        console2.log("MundialHook :", address(hook));
        console2.log("PoolManager :", address(cfg.poolManager));
        console2.log("currency0   :", Currency.unwrap(key.currency0));
        console2.log("currency1   :", Currency.unwrap(key.currency1));
        console2.log("PoolId      :");
        console2.logBytes32(PoolId.unwrap(key.toId()));
        console2.log("kickoff     :", cfg.kickoff);
    }
}
