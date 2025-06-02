// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "src/state_reader/PreviewVaultStateReader.sol";
import "src/state_reader/MaxDepositMintCollateralVaultStateReader.sol";
import "src/state_reader/MaxWithdrawRedeemCollateralVaultStateReader.sol";

abstract contract CollateralVaultRead is
    PreviewVaultStateReader,
    MaxDepositMintCollateralVaultStateReader,
    MaxWithdrawRedeemCollateralVaultStateReader
{
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewDepositCollateral(assets, previewVaultState());
    }

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewWithdrawCollateral(assets, previewVaultState());
    }

    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewMintCollateral(shares, previewVaultState());
    }

    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewRedeemCollateral(shares, previewVaultState());
    }

    function maxDepositCollateral(address) external view returns (uint256) {
        return modules.collateralVaultModule().maxDepositCollateral(maxDepositMintCollateralVaultState());
    }

    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return modules.collateralVaultModule().maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function maxMintCollateral(address) external view returns (uint256) {
        return modules.collateralVaultModule().maxMintCollateral(maxDepositMintCollateralVaultState());
    }

    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return modules.collateralVaultModule().maxRedeemCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().convertToSharesCollateral(assets, maxGrowthFeeState());
    }

    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().convertToAssetsCollateral(shares, maxGrowthFeeState());
    }

    function totalAssetsCollateral() external view returns (uint256) {
        return modules.collateralVaultModule().totalAssetsCollateral(totalAssetsState());
    }

    function totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return modules.collateralVaultModule().totalAssetsCollateral(isDeposit, totalAssetsState());
    }
}
