// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ILowLevelRebalanceErrors
 * @notice Interface defining all custom errors used in low-level rebalancing operations
 * @dev This interface contains error definitions for low-level rebalancing operations
 *      that help maintain vault stability during rebalancing by enforcing limits
 *      on collateral, borrow, and share changes.
 * @author LTV Protocol
 */
interface ILowLevelRebalanceErrors {
    /**
     * @notice Error thrown when collateral delta exceeds the maximum allowed during low-level rebalancing
     * @param deltaCollateral The change in collateral amount (can be positive or negative)
     * @param max The maximum allowed absolute change in collateral
     * @dev Prevents excessive collateral changes during rebalancing that could destabilize the vault
     *      The deltaCollateral can be positive (increase) or negative (decrease)
     */
    error ExceedsLowLevelRebalanceMaxDeltaCollateral(int256 deltaCollateral, int256 max);

    /**
     * @notice Error thrown when borrow delta exceeds the maximum allowed during low-level rebalancing
     * @param deltaBorrow The change in borrow amount (can be positive or negative)
     * @param max The maximum allowed absolute change in borrow
     * @dev Prevents excessive borrow changes during rebalancing that could affect vault risk parameters
     *      The deltaBorrow can be positive (increase) or negative (decrease)
     */
    error ExceedsLowLevelRebalanceMaxDeltaBorrow(int256 deltaBorrow, int256 max);

    /**
     * @notice Error thrown when shares delta exceeds the maximum allowed during low-level rebalancing
     * @param deltaShares The change in shares amount (can be positive or negative)
     * @param max The maximum allowed absolute change in shares
     * @dev Prevents excessive share changes during rebalancing that could impact vault stability
     *      The deltaShares can be positive (increase) or negative (decrease)
     */
    error ExceedsLowLevelRebalanceMaxDeltaShares(int256 deltaShares, int256 max);

    /**
     * @notice Error thrown when target LTV is zero, which disables borrow functionality
     * @dev This error occurs when the target Loan-to-Value ratio is set to zero,
     *      making it impossible to perform borrow operations during rebalancing
     */
    error ZerotargetLtvDisablesBorrow();
}
