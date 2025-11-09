// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionState} from "../../../structs/state/auction/AuctionState.sol";
import {AuctionData} from "../../../structs/data/auction/AuctionData.sol";
import {DeltaAuctionState} from "../../../structs/state_transition/DeltaAuctionState.sol";
import {AuctionStateToData} from "../../../math/abstracts/AuctionStateToData.sol";
import {AuctionMath} from "../../../math/libraries/AuctionMath.sol";
import {NonReentrantRead} from "../../../modifiers/NonReentrantRead.sol";

/**
 * @title PreviewExecuteAuctionBorrow
 * @notice This contract contains preview execute auction borrow function implementation.
 */
abstract contract PreviewExecuteAuctionBorrow is AuctionStateToData, NonReentrantRead {
    /**
     * @dev see IAuctionModule.previewExecuteAuctionBorrow
     */
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionState memory auctionState)
        external
        view
        nonReentrantRead
        returns (int256)
    {
        return _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToData(auctionState))
            .deltaUserCollateralAssets;
    }

    /**
     * @dev main function to calculate preview execute auction borrow using transformed auction data
     */
    function _previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionData memory auctionData)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        return AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, auctionData);
    }
}
