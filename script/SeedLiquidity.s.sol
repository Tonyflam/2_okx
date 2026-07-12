// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IAllowanceTransfer {
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

/// @notice Seeds initial full-range liquidity in the Mundial pool through the
/// official v4 PositionManager (Permit2 flow).
///
/// Environment:
///   PRIVATE_KEY, POSITION_MANAGER, PERMIT2 (0x000000000022D473030F116dDEE9F6B43aC78BA3),
///   TOKEN (MUNDIAL), QUOTE_TOKEN, HOOK, TICK_SPACING (60),
///   LIQUIDITY (raw L, default 1e21), AMOUNT_MAX (per-token cap, default 5e22)
contract SeedLiquidity is Script {
    function run() external {
        IPositionManager posm = IPositionManager(vm.envAddress("POSITION_MANAGER"));
        IAllowanceTransfer permit2 = IAllowanceTransfer(vm.envAddress("PERMIT2"));
        address token = vm.envAddress("TOKEN");
        address quote = vm.envAddress("QUOTE_TOKEN");
        address hook = vm.envAddress("HOOK");
        int24 tickSpacing = int24(int256(vm.envOr("TICK_SPACING", uint256(60))));
        uint256 liquidity = vm.envOr("LIQUIDITY", uint256(1e21));
        uint256 amountMax = vm.envOr("AMOUNT_MAX", uint256(5e22));

        (Currency c0, Currency c1) =
            token < quote ? (Currency.wrap(token), Currency.wrap(quote)) : (Currency.wrap(quote), Currency.wrap(token));
        PoolKey memory key = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: tickSpacing,
            hooks: IHooks(hook)
        });

        // Widest tick range aligned to spacing.
        int24 tickLower = (int24(-887272) / tickSpacing) * tickSpacing;
        int24 tickUpper = (int24(887272) / tickSpacing) * tickSpacing;

        vm.startBroadcast();

        IERC20(token).approve(address(permit2), type(uint256).max);
        IERC20(quote).approve(address(permit2), type(uint256).max);
        permit2.approve(token, address(posm), type(uint160).max, type(uint48).max);
        permit2.approve(quote, address(posm), type(uint160).max, type(uint48).max);

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(key, tickLower, tickUpper, liquidity, amountMax, amountMax, msg.sender, bytes(""));
        params[1] = abi.encode(key.currency0, key.currency1);
        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp + 300);

        vm.stopBroadcast();

        console2.log("Seeded liquidity", liquidity);
        console2.log("Range", tickLower);
        console2.log("   to", tickUpper);
    }
}
