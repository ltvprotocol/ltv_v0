// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionState} from "src/structs/state/auction/AuctionState.sol";
import {AuctionData} from "src/structs/data/auction/AuctionData.sol";
import {DeltaAuctionState} from "src/structs/state_transition/DeltaAuctionState.sol";
import {AuctionStateToData} from "src/math/abstracts/AuctionStateToData.sol";
import {AuctionMath} from "src/math/libraries/AuctionMath.sol";

abstract contract PreviewExecuteAuctionBorrow is AuctionStateToData {
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionState memory auctionState)
        external
        view
        returns (int256)
    {
        return _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToData(auctionState))
            .deltaUserCollateralAssets;
    }

    function _previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionData memory auctionData)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        return AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, auctionData);
    }
}
