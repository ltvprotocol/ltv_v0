// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct AuctionData {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    int256 auctionStep;
}
