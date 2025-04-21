// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/readers/ModulesAddressStateReader.sol';
import '../../states/readers/ApplicationStateReader.sol';

abstract contract CollateralVaultRead is ApplicationStateReader, ModulesAddressStateReader {
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewDepositCollateral(assets, previewVaultState());
    }

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewWithdrawCollateral(assets, previewVaultState());
    }

    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewMintCollateral(shares, previewVaultState());
    }

    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewRedeemCollateral(shares, previewVaultState());
    }

    function maxDepositCollateral(address) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxDepositCollateral(maxDepositMintCollateralVaultState());
    }

    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function maxMintCollateral(address) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxMintCollateral(maxDepositMintCollateralVaultState());
    }

    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxRedeemCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().convertToSharesCollateral(assets, maxGrowthFeeState());
    }

    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().convertToAssetsCollateral(shares, maxGrowthFeeState());
    }

    function totalAssetsCollateral() external view returns (uint256) {
        return getModules().collateralVaultsRead().totalAssetsCollateral(totalAssetsState());
    }

    function _totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return getModules().collateralVaultsRead().totalAssetsCollateral(isDeposit, totalAssetsState());
    }
}
