// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseAllFunctionsInvariantTest} from "./utils/BaseAllFunctionsInvariantTest.t.sol";

contract NormalDecimalsAllFunctionsTest is BaseAllFunctionsInvariantTest {
    /// forge-config: default.invariant.runs = 10
    function invariant_allFunctionsNormalDecimals() public {}
}
