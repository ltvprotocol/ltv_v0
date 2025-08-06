// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/AuctionState.sol";
import "src/structs/data/AuctionData.sol";
import "./CommonMath.sol";

abstract contract AuctionStateToData {
    function auctionStateToData(AuctionState memory auctionState) internal view returns (AuctionData memory) {
        return AuctionData({
            futureBorrowAssets: auctionState.futureBorrowAssets,
            futureCollateralAssets: auctionState.futureCollateralAssets,
            futureRewardBorrowAssets: auctionState.futureRewardBorrowAssets,
            futureRewardCollateralAssets: auctionState.futureRewardCollateralAssets,
            auctionStep: CommonMath.calculateAuctionStep(
                auctionState.startAuction, uint56(block.number), auctionState.auctionDuration
            ),
            auctionDuration: auctionState.auctionDuration
        });
    }
}
