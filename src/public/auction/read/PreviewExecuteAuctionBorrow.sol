// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/math/AuctionMath.sol';
import 'src/math/AuctionStateToData.sol';
import 'src/structs/state_transition/DeltaAuctionState.sol';

abstract contract PreviewExecuteAuctionBorrow is AuctionStateToData {
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionState memory auctionState) external view returns (int256) {
        return _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToData(auctionState)).deltaUserCollateralAssets;
    }

    function _previewExecuteAuctionBorrow(
        int256 deltaUserBorrowAssets,
        AuctionData memory auctionData
    ) internal pure returns (DeltaAuctionState memory) {
        return AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, auctionData);
    }
} 