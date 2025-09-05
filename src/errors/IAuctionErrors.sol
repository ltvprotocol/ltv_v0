// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAuctionErrors
 * @notice Interface defining all custom errors used in auction operations within the LTV vault system
 * @dev This interface contains error definitions for auction-related operations,
 *      including validation of future collateral/borrow assets and delta calculations.
 *      These errors help ensure auction integrity and prevent invalid auction states.
 * @author LTV Protocol
 */
interface IAuctionErrors {
    /**
     * @notice Error thrown when no auction can be created for the provided delta future collateral
     * @param futureCollateralAssets The expected future collateral assets in the vault
     * @param futureRewardCollateralAssets The expected future reward collateral assets
     * @param deltaUserCollateralAssets The change in user collateral assets
     * @dev This error occurs when the combination of future collateral values and user delta
     *      doesn't meet the requirements for creating a valid auction
     */
    error NoAuctionForProvidedDeltaFutureCollateral(
        int256 futureCollateralAssets, int256 futureRewardCollateralAssets, int256 deltaUserCollateralAssets
    );

    /**
     * @notice Error thrown when no auction can be created for the provided delta future borrow
     * @param futureBorrowAssets The expected future borrow assets in the vault
     * @param futureRewardBorrowAssets The expected future reward borrow assets
     * @param deltaUserBorrowAssets The change in user borrow assets
     * @dev This error occurs when the combination of future borrow values and user delta
     *      doesn't meet the requirements for creating a valid auction
     */
    error NoAuctionForProvidedDeltaFutureBorrow(
        int256 futureBorrowAssets, int256 futureRewardBorrowAssets, int256 deltaUserBorrowAssets
    );

    /**
     * @notice Error thrown when the delta user borrow assets doesn't match the calculated expected value
     * @param deltaUserBorrowAssets The provided delta user borrow assets
     * @param calculatedDeltaUserBorrowAssets The calculated expected delta user borrow assets
     * @dev This error occurs when there's a mismatch between the provided and calculated
     *      delta values for user borrow assets, indicating potential calculation errors
     */
    error UnexpectedDeltaUserBorrowAssets(int256 deltaUserBorrowAssets, int256 calculatedDeltaUserBorrowAssets);

    /**
     * @notice Error thrown when the delta user collateral assets doesn't match the calculated expected value
     * @param deltaUserCollateralAssets The provided delta user collateral assets
     * @param calculatedDeltaUserCollateralAssets The calculated expected delta user collateral assets
     * @dev This error occurs when there's a mismatch between the provided and calculated
     *      delta values for user collateral assets, indicating potential calculation errors
     */
    error UnexpectedDeltaUserCollateralAssets(
        int256 deltaUserCollateralAssets, int256 calculatedDeltaUserCollateralAssets
    );
}
