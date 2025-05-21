// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAuctionEvent {
    event AuctionExecuted(address executor, int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets);
}
