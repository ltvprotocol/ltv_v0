// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title NextState
 * @notice This struct represents next protocol state
 * in underlying assets after vault calculations
 */
struct NextState {
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    uint56 startAuction;
    bool merge;
}
