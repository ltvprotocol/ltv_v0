// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultStateReader} from
    "src/state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxWithdrawRedeemCollateralVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";

abstract contract CollateralVaultRead is
    MaxDepositMintCollateralVaultStateReader,
    MaxWithdrawRedeemCollateralVaultStateReader
{
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewDepositCollateral(assets, previewDepositVaultState());
    }

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewWithdrawCollateral(assets, previewWithdrawVaultState());
    }

    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewMintCollateral(shares, previewDepositVaultState());
    }

    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewRedeemCollateral(shares, previewWithdrawVaultState());
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
        return modules.collateralVaultModule().totalAssetsCollateral(totalAssetsState(false));
    }

    function totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return modules.collateralVaultModule().totalAssetsCollateral(isDeposit, totalAssetsState(isDeposit));
    }
}
