// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title DeltaAuctionState
 * @notice This struct represents changes of state after auction calculations
 */
struct DeltaAuctionState {
    int256 deltaFutureBorrowAssets;
    int256 deltaFutureCollateralAssets;
    int256 deltaUserCollateralAssets;
    int256 deltaUserBorrowAssets;
    int256 deltaUserFutureRewardCollateralAssets;
    int256 deltaUserFutureRewardBorrowAssets;
    int256 deltaProtocolFutureRewardCollateralAssets;
    int256 deltaProtocolFutureRewardBorrowAssets;
}
