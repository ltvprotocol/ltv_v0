// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ILowLevelRebalanceEvent {
    event LowLevelRebalanceExecuted(
        address indexed executor, int256 deltaRealCollateralAsset, int256 deltaRealBorrowAssets, int256 deltaShares
    );
}
