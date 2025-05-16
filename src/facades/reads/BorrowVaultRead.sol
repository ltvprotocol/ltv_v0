// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/LTVState.sol';

abstract contract BorrowVaultRead is LTVState {
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return modules.borrowVault().previewDeposit(assets, previewVaultState());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return modules.borrowVault().previewWithdraw(assets, previewVaultState());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return modules.borrowVault().previewMint(shares, previewVaultState());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return modules.borrowVault().previewRedeem(shares, previewVaultState());
    }

    function maxDeposit(address) external view returns (uint256) {
        return modules.borrowVault().maxDeposit(maxDepositMintBorrowVaultState());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return modules.borrowVault().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function maxMint(address) external view returns (uint256) {
        return modules.borrowVault().maxMint(maxDepositMintBorrowVaultState());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return modules.borrowVault().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return modules.borrowVault().convertToShares(assets, maxGrowthFeeState());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return modules.borrowVault().convertToAssets(shares, maxGrowthFeeState());
    }

    function totalAssets() external view returns (uint256) {
        return modules.borrowVault().totalAssets(totalAssetsState());
    }

    function totalAssets(bool isDeposit) external view returns (uint256) {
        return modules.borrowVault().totalAssets(isDeposit, totalAssetsState());
    }
}
