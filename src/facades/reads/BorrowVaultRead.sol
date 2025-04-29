// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../../states/readers/ApplicationStateReader.sol";

abstract contract BorrowVaultRead is ApplicationStateReader, ModulesAddressStateReader {
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewDeposit(assets, previewVaultState());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewWithdraw(assets, previewVaultState());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewMint(shares, previewVaultState());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewRedeem(shares, previewVaultState());
    }

    function maxDeposit(address) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxDeposit(maxDepositMintBorrowVaultState());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function maxMint(address) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxMint(maxDepositMintBorrowVaultState());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().convertToShares(assets, maxGrowthFeeState());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().convertToAssets(shares, maxGrowthFeeState());
    }
    
    function totalAssets() external view returns (uint256) {
        return getModules().borrowVaultsRead().totalAssets(totalAssetsState());
    }
    
    function _totalAssets(bool isDeposit) external view returns (uint256) {
        return getModules().borrowVaultsRead().totalAssets(isDeposit, totalAssetsState());
    }
} 