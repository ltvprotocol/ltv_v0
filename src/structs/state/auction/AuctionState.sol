// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title AuctionState
 * @notice This struct needed for auction calculations
 */
struct AuctionState {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint56 startAuction;
    uint24 auctionDuration;
}
