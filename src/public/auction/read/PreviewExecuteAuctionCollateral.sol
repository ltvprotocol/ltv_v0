// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionState} from "src/structs/state/AuctionState.sol";
import {AuctionData} from "src/structs/data/AuctionData.sol";
import {DeltaAuctionState} from "src/structs/state_transition/DeltaAuctionState.sol";
import {AuctionStateToData} from "src/math/AuctionStateToData.sol";
import {AuctionMath} from "src/math/AuctionMath.sol";

/**
 * @title PreviewExecuteAuctionCollateral
 * @notice This contract contains preview execute auction collateral function implementation.
 */
abstract contract PreviewExecuteAuctionCollateral is AuctionStateToData {
    /**
     * @dev see IAuctionModule.previewExecuteAuctionCollateral
     */
    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionState memory auctionState)
        external
        view
        returns (int256)
    {
        return _previewExecuteAuctionCollateral(deltaUserCollateralAssets, auctionStateToData(auctionState))
            .deltaUserBorrowAssets;
    }

    /**
     * @dev main function to calculate preview execute auction collateral using transformed auction data
     */
    function _previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionData memory auctionData)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        return AuctionMath.calculateExecuteAuctionCollateral(deltaUserCollateralAssets, auctionData);
    }
}
