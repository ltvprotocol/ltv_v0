// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionState} from "src/structs/state/auction/AuctionState.sol";

/**
 * @title IAuctionModule
 * @notice Interface defining all read functions for the auction module in the LTV vault system
 * @dev This interface contains read functions for the auction part of the LTV protocol
 * @author LTV Protocol
 */
interface IAuctionModule {
    /**
     * @dev Module function for ILTV.previewExecuteAuctionBorrow. Also receives cached state for
     * subsequent calculations.
     */
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionState memory auctionState)
        external
        view
        returns (int256);

    /**
     * @dev Module function for ILTV.previewExecuteAuctionCollateral. Also receives cached state for
     * subsequent calculations.
     */
    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionState memory auctionState)
        external
        view
        returns (int256);
}
