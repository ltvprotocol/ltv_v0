// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteLowLevelRebalanceCollateral} from
    "src/public/low_level/write/execute/ExecuteLowLevelRebalanceCollateral.sol";
import {ExecuteLowLevelRebalanceBorrow} from "src/public/low_level/write/execute/ExecuteLowLevelRebalanceBorrow.sol";
import {ExecuteLowLevelRebalanceShares} from "src/public/low_level/write/execute/ExecuteLowLevelRebalanceShares.sol";

/**
 * @title LowLevelRebalanceModule
 * @notice Low level rebalance module for LTV protocol
 */
contract LowLevelRebalanceModule is
    ExecuteLowLevelRebalanceCollateral,
    ExecuteLowLevelRebalanceBorrow,
    ExecuteLowLevelRebalanceShares
{
    constructor() {
        _disableInitializers();
    }
}
