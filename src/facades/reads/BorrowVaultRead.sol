// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";    

abstract contract BorrowVaultRead is LTVState {
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultsRead().previewDeposit(assets, previewVaultState());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultsRead().previewWithdraw(assets, previewVaultState());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultsRead().previewMint(shares, previewVaultState());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultsRead().previewRedeem(shares, previewVaultState());
    }

    function maxDeposit(address) external view returns (uint256) {
        return modules.borrowVaultsRead().maxDeposit(maxDepositMintBorrowVaultState());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return modules.borrowVaultsRead().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function maxMint(address) external view returns (uint256) {
        return modules.borrowVaultsRead().maxMint(maxDepositMintBorrowVaultState());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return modules.borrowVaultsRead().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultsRead().convertToShares(assets, maxGrowthFeeState());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultsRead().convertToAssets(shares, maxGrowthFeeState());
    }
    
    function totalAssets() external view returns (uint256) {
        return modules.borrowVaultsRead().totalAssets(totalAssetsState());
    }
    
    function totalAssets(bool isDeposit) external view returns (uint256) {
        return modules.borrowVaultsRead().totalAssets(isDeposit, totalAssetsState());
    }
} 