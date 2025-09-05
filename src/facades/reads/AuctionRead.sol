// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GetAuctionStateReader} from "src/state_reader/GetAuctionStateReader.sol";

/**
 * @title AuctionRead
 * @notice This contract contains all the read functions for the auction part of the LTV protocol.
 * It retrieves auction state and delegates all the calculations to the auction module.
 */
abstract contract AuctionRead is GetAuctionStateReader {
    /**
     * @dev see ILTV.previewExecuteAuctionBorrow
     */
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        return modules.auctionModule().previewExecuteAuctionBorrow(deltaUserBorrowAssets, getAuctionState());
    }

    /**
     * @dev see ILTV.previewExecuteAuctionCollateral
     */
    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        return modules.auctionModule().previewExecuteAuctionCollateral(deltaUserCollateralAssets, getAuctionState());
    }
}
