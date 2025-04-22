// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/math2/AuctionMath.sol';
import 'src/math2/CommonMath.sol';

contract PreviewAuction {
    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionState memory auctionState) external view returns (int256) {
        return _previewExecuteAuctionCollateral(deltaUserCollateralAssets, auctionStateToAuctionData(auctionState)).deltaUserBorrowAssets;
    }

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionState memory auctionState) external view returns (int256) {
        return _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToAuctionData(auctionState)).deltaUserCollateralAssets;
    }

    function _previewExecuteAuctionBorrow(
        int256 deltaUserBorrowAssets,
        AuctionData memory auctionData
    ) internal pure returns (DeltaAuctionState memory) {
        return AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, auctionData);
    }

    function _previewExecuteAuctionCollateral(
        int256 deltaUserCollateralAssets,
        AuctionData memory auctionData
    ) internal pure returns (DeltaAuctionState memory) {
        return AuctionMath.calculateExecuteAuctionCollateral(deltaUserCollateralAssets, auctionData);
    }

    function auctionStateToAuctionData(AuctionState memory auctionState) internal view returns (AuctionData memory) {
        return
            AuctionData({
                futureBorrowAssets: auctionState.futureBorrowAssets,
                futureCollateralAssets: auctionState.futureCollateralAssets,
                futureRewardBorrowAssets: auctionState.futureRewardBorrowAssets,
                futureRewardCollateralAssets: auctionState.futureRewardCollateralAssets,
                auctionStep: int256(CommonMath.calculateAuctionStep(auctionState.startAuction, block.number))
            });
    }
}
