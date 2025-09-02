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
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewDeposit(assets, previewDepositVaultState());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewWithdraw(assets, previewWithdrawVaultState());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewMint(shares, previewDepositVaultState());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewRedeem(shares, previewWithdrawVaultState());
    }

    function maxDeposit(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxDeposit(maxDepositMintBorrowVaultState());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function maxMint(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxMint(maxDepositMintBorrowVaultState());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().convertToShares(assets, maxGrowthFeeState());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().convertToAssets(shares, maxGrowthFeeState());
    }

    // default behavior - don't overestimate our assets
    function totalAssets() external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(totalAssetsState(false));
    }

    function totalAssets(bool isDeposit) external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(isDeposit, totalAssetsState(isDeposit));
    }
}
