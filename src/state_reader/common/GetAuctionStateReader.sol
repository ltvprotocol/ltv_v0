// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionState} from "src/structs/state/auction/AuctionState.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title GetAuctionStateReader
 * @notice contract contains functionality to retrieve pure auction state
 * needed for auction calculations
 */
contract GetAuctionStateReader is LTVState {
    /**
     * @dev function to retrieve pure auction state auction calculations
     */
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
