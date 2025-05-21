// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IStateUpdateEvent {
    event StateUpdated(
        int256 oldFutureBorrowAssets,
        int256 oldFutureCollateralAssets,
        int256 oldFutureRewardBorrowAssets,
        int256 oldFutureRewardCollateralAssets,
        uint256 oldStartAuction,
        int256 newFutureBorrowAssets,
        int256 newFutureCollateralAssets,
        int256 newFutureRewardBorrowAssets,
        int256 newFutureRewardCollateralAssets,
        uint256 newStartAuction
    );
}
