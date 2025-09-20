// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseAllFunctionsInvariantTest} from "test/invariant/utils/BaseAllFunctionsInvariantTest.t.sol";

contract AllFunctionsSmallCollateralBigBorrowDecimalsTest is BaseAllFunctionsInvariantTest {
    function _getBorrowTokenDecimals() internal pure override returns (uint8) {
        return 20;
    }

    function _getCollateralTokenDecimals() internal pure override returns (uint8) {
        return 6;
    }
    /// forge-config: default.invariant.runs = 120

    function invariant_allFunctionsSmallCollateralBigBorrowDecimals() public {}
}
