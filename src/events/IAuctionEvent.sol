// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAuctionEvent
 * @notice Interface defining all events emitted during auction operations in the LTV vault system
 * @dev This interface contains event definitions for auction-related operations,
 *      including the execution of auctions and the resulting collateral/borrow changes.
 *      These events provide transparency and allow external systems to track auction activities.
 * @author LTV Protocol
 */
interface IAuctionEvent {
    /**
     * @notice Emitted when an auction is successfully executed
     * @param executor The address that executed the auction
     * @param deltaRealCollateralAssets The change in real collateral assets after the auction
     * @param deltaRealBorrowAssets The change in real borrow assets after the auction
     * @dev This event is emitted when an auction is successfully executed,
     *      providing details about the changes in real collateral and borrow assets.
     */
    event AuctionExecuted(address executor, int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets);
}
