// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DeltaSharesAndDeltaRealBorrowData} from "src/structs/data/vault/DeltaSharesAndDeltaRealBorrowData.sol";
import {DeltaSharesAndDeltaRealCollateralData} from "src/structs/data/vault/DeltaSharesAndDeltaRealCollateralData.sol";
import {DeltaRealBorrowAndDeltaRealCollateralData} from
    "src/structs/data/vault/DeltaRealBorrowAndDeltaRealCollateralData.sol";

/**
 * @title IVaultErrors
 * @notice Interface defining all custom errors used in the LTV vault operations
 * @dev This interface contains error definitions for vault operations including
 *      deposit/withdraw limits, mint/redeem limits, and unexpected data state errors.
 *      These errors help maintain vault safety and prevent excessive operations.
 * @author LTV Protocol
 */
interface IVaultErrors {
    /**
     * @notice Error thrown when there's an unexpected error in delta shares and delta real borrow data
     * @param data The DeltaSharesAndDeltaRealBorrowData struct containing the problematic data
     * @dev This error occurs when the vault encounters unexpected or invalid state
     *      in the relationship between share changes and borrow changes
     */
    error DeltaSharesAndDeltaRealBorrowUnexpectedError(DeltaSharesAndDeltaRealBorrowData data);

    /**
     * @notice Error thrown when there's an unexpected error in delta shares and delta real collateral data
     * @param data The DeltaSharesAndDeltaRealCollateralData struct containing the problematic data
     * @dev This error occurs when the vault encounters unexpected or invalid state
     *      in the relationship between share changes and collateral changes
     */
    error DeltaSharesAndDeltaRealCollateralUnexpectedError(DeltaSharesAndDeltaRealCollateralData data);

    /**
     * @notice Error thrown when there's an unexpected error in delta real borrow and delta real collateral data
     * @param data The DeltaRealBorrowAndDeltaRealCollateralData struct containing the problematic data
     * @dev This error occurs when the vault encounters unexpected or invalid state
     *      in the relationship between borrow changes and collateral changes
     */
    error DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(DeltaRealBorrowAndDeltaRealCollateralData data);

    /**
     * @notice Error thrown when deposit amount exceeds the maximum allowed
     * @param receiver The address attempting to receive the deposit
     * @param assets The amount of assets being deposited
     * @param max The maximum allowed deposit amount
     * @dev Prevents excessive deposits that could destabilize the vault
     */
    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @notice Error thrown when withdrawal amount exceeds the maximum allowed
     * @param owner The address attempting to withdraw assets
     * @param assets The amount of assets being withdrawn
     * @param max The maximum allowed withdrawal amount
     * @dev Prevents excessive withdrawals that could impact vault liquidity
     */
    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @notice Error thrown when mint amount exceeds the maximum allowed
     * @param receiver The address attempting to receive the minted shares
     * @param shares The amount of shares being minted
     * @param max The maximum allowed mint amount
     * @dev Prevents excessive share minting that could dilute existing holders
     */
    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @notice Error thrown when redeem amount exceeds the maximum allowed
     * @param owner The address attempting to redeem shares
     * @param shares The amount of shares being redeemed
     * @param max The maximum allowed redeem amount
     * @dev Prevents excessive share redemption that could impact vault stability
     */
    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @notice Error thrown when collateral deposit amount exceeds the maximum allowed
     * @param receiver The address attempting to receive the collateral deposit
     * @param assets The amount of collateral assets being deposited
     * @param max The maximum allowed collateral deposit amount
     * @dev Prevents excessive collateral deposits that could affect vault risk parameters
     */
    error ExceedsMaxDepositCollateral(address receiver, uint256 assets, uint256 max);

    /**
     * @notice Error thrown when collateral withdrawal amount exceeds the maximum allowed
     * @param owner The address attempting to withdraw collateral assets
     * @param assets The amount of collateral assets being withdrawn
     * @param max The maximum allowed collateral withdrawal amount
     * @dev Prevents excessive collateral withdrawals that could impact vault solvency
     */
    error ExceedsMaxWithdrawCollateral(address owner, uint256 assets, uint256 max);

    /**
     * @notice Error thrown when collateral mint amount exceeds the maximum allowed
     * @param receiver The address attempting to receive the minted collateral shares
     * @param shares The amount of collateral shares being minted
     * @param max The maximum allowed collateral mint amount
     * @dev Prevents excessive collateral share minting that could affect vault risk management
     */
    error ExceedsMaxMintCollateral(address receiver, uint256 shares, uint256 max);

    /**
     * @notice Error thrown when collateral redeem amount exceeds the maximum allowed
     * @param owner The address attempting to redeem collateral shares
     * @param shares The amount of collateral shares being redeemed
     * @param max The maximum allowed collateral redeem amount
     * @dev Prevents excessive collateral share redemption that could impact vault stability
     */
    error ExceedsMaxRedeemCollateral(address owner, uint256 shares, uint256 max);
}
