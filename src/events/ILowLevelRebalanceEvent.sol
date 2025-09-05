// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ILowLevelRebalanceEvent
 * @notice Interface defining all events emitted during low level rebalancing operations in the LTV vault system
 * @dev This interface contains event definitions for low level rebalancing-related operations,
 *      including the execution of low level rebalancing and the resulting collateral/borrow changes.
 *      These events provide transparency and allow external systems to track low level rebalancing activities.
 * @author LTV Protocol
 */
interface ILowLevelRebalanceEvent {
    /**
     * @notice Emitted when low level rebalance is executed
     * @param executor The address that executed the low level rebalance
     * @param deltaRealCollateralAsset The change in real collateral assets after the low level rebalance
     * @param deltaRealBorrowAssets The change in real borrow assets after the low level rebalance
     * @param deltaShares The change in shares after the low level rebalance
     * @dev This event is emitted when low level rebalance is executed,
     *      providing details about the changes in real collateral and borrow assets.
     */
    event LowLevelRebalanceExecuted(
        address indexed executor, int256 deltaRealCollateralAsset, int256 deltaRealBorrowAssets, int256 deltaShares
    );
}
