// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {NextState} from "NextState.sol";

/**
 * @title NextStateData
 * @notice This struct contains data for next state calculations
 */
struct NextStateData {
    NextState nextState;
    uint256 borrowPrice;
    uint256 collateralPrice;
    uint8 borrowTokenDecimals;
    uint8 collateralTokenDecimals;
}
