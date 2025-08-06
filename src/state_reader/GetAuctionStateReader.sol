// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/AuctionState.sol";
import "src/states/LTVState.sol";

contract GetAuctionStateReader is LTVState {
    function getAuctionState() internal view returns (AuctionState memory) {
        return AuctionState({
            futureCollateralAssets: futureCollateralAssets,
            futureBorrowAssets: futureBorrowAssets,
            futureRewardBorrowAssets: futureRewardBorrowAssets,
            futureRewardCollateralAssets: futureRewardCollateralAssets,
            startAuction: startAuction,
            auctionDuration: auctionDuration
        });
    }
}
