// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct NextState {
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    uint56 startAuction;
    bool merge;
    uint256 borrowPrice;
    uint256 collateralPrice;
}
