// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @title MundialToken ($MUNDIAL) — the match ball of the Mundial pool.
/// @notice Plain fixed-supply ERC20. The entire supply is minted once at
/// deployment to the deployer, who seeds the Uniswap v4 pool with it. No
/// owner, no minting, no pausing, no transfer hooks, no blacklist.
contract MundialToken is ERC20 {
    /// @param recipient Receives the full fixed supply.
    /// @param supply Total supply in wei units (18 decimals).
    constructor(address recipient, uint256 supply) ERC20("Mundial", "MUNDIAL", 18) {
        _mint(recipient, supply);
    }
}
