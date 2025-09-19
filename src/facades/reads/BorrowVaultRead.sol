// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultStateReader} from "src/state_reader/vault/PreviewDepositVaultStateReader.sol";
import {PreviewWithdrawVaultStateReader} from "src/state_reader/vault/PreviewWithdrawVaultStateReader.sol";
import {MaxDepositMintBorrowVaultStateReader} from "src/state_reader/vault/MaxDepositMintBorrowVaultStateReader.sol";
import {MaxWithdrawRedeemBorrowVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemBorrowVaultStateReader.sol";

/**
 * @title BorrowVaultRead
 * @notice This contract contains all the read functions for the borrow vault part of the LTV protocol.
 * It retrieves appropriate function state and delegates all the calculations to the borrow vault module.
 */
abstract contract BorrowVaultRead is
    PreviewDepositVaultStateReader,
    PreviewWithdrawVaultStateReader,
    MaxDepositMintBorrowVaultStateReader,
    MaxWithdrawRedeemBorrowVaultStateReader
{
    /**
     * @dev see ILTV.previewDeposit
     */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewDeposit(assets, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewWithdraw
     */
    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewWithdraw(assets, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.previewMint
     */
    function previewMint(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewMint(shares, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewRedeem
     */
    function previewRedeem(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewRedeem(shares, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.maxDeposit
     */
    function maxDeposit(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxDeposit(maxDepositMintBorrowVaultState());
    }

    /**
     * @dev see ILTV.maxWithdraw
     */
    function maxWithdraw(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    /**
     * @dev see ILTV.maxMint
     */
    function maxMint(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxMint(maxDepositMintBorrowVaultState());
    }

    /**
     * @dev see ILTV.maxRedeem
     */
    function maxRedeem(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    /**
     * @dev see ILTV.convertToShares
     */
    function convertToShares(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().convertToShares(assets, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.convertToAssets
     */
    function convertToAssets(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().convertToAssets(shares, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.totalAssets
     * Default behavior - don't overestimate our assets
     */
    function totalAssets() external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(totalAssetsState(false));
    }

    /**
     * @dev see ILTV.totalAssets
     */
    function totalAssets(bool isDeposit) external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(isDeposit, totalAssetsState(isDeposit));
    }

    function asset() external view returns (address) {
        return address(borrowToken);
    }
}
