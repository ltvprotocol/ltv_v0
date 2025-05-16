// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/LTVState.sol';

abstract contract CollateralVaultRead is LTVState {
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVault().previewDepositCollateral(assets, previewVaultState());
    }

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVault().previewWithdrawCollateral(assets, previewVaultState());
    }

    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVault().previewMintCollateral(shares, previewVaultState());
    }

    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVault().previewRedeemCollateral(shares, previewVaultState());
    }

    function maxDepositCollateral(address) external view returns (uint256) {
        return modules.collateralVault().maxDepositCollateral(maxDepositMintCollateralVaultState());
    }

    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return modules.collateralVault().maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function maxMintCollateral(address) external view returns (uint256) {
        return modules.collateralVault().maxMintCollateral(maxDepositMintCollateralVaultState());
    }

    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return modules.collateralVault().maxRedeemCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVault().convertToSharesCollateral(assets, maxGrowthFeeState());
    }

    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVault().convertToAssetsCollateral(shares, maxGrowthFeeState());
    }
    
    function totalAssetsCollateral() external view returns (uint256) {
        return modules.collateralVault().totalAssetsCollateral(totalAssetsState());
    }
    
    function totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return modules.collateralVault().totalAssetsCollateral(isDeposit, totalAssetsState());
    }
}
