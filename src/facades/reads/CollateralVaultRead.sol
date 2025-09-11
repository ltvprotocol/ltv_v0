// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultStateReader} from
    "src/state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxWithdrawRedeemCollateralVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";

/**
 * @title CollateralVaultRead
 * @notice This contract contains all the read functions for the collateral vault part of the LTV protocol.
 * It retrieves appropriate function state and delegates all the calculations to the collateral vault module.
 */
abstract contract CollateralVaultRead is
    MaxDepositMintCollateralVaultStateReader,
    MaxWithdrawRedeemCollateralVaultStateReader
{
    /**
     * @dev see ILTV.previewDepositCollateral
     */
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewDepositCollateral(assets, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewWithdrawCollateral
     */
    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().previewWithdrawCollateral(assets, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.previewMintCollateral
     */
    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewMintCollateral(shares, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewRedeemCollateral
     */
    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().previewRedeemCollateral(shares, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.maxDepositCollateral
     */
    function maxDepositCollateral(address) external view returns (uint256) {
        return modules.collateralVaultModule().maxDepositCollateral(maxDepositMintCollateralVaultState());
    }

    /**
     * @dev see ILTV.maxWithdrawCollateral
     */
    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return modules.collateralVaultModule().maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    /**
     * @dev see ILTV.maxMintCollateral
     */
    function maxMintCollateral(address) external view returns (uint256) {
        return modules.collateralVaultModule().maxMintCollateral(maxDepositMintCollateralVaultState());
    }

    /**
     * @dev see ILTV.maxRedeemCollateral
     */
    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return modules.collateralVaultModule().maxRedeemCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    /**
     * @dev see ILTV.convertToSharesCollateral
     */
    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return modules.collateralVaultModule().convertToSharesCollateral(assets, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.convertToAssetsCollateral
     */
    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return modules.collateralVaultModule().convertToAssetsCollateral(shares, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.totalAssetsCollateral
     */
    function totalAssetsCollateral() external view returns (uint256) {
        return modules.collateralVaultModule().totalAssetsCollateral(totalAssetsState(false));
    }

    /**
     * @dev see ILTV.totalAssetsCollateral
     */
    function totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return modules.collateralVaultModule().totalAssetsCollateral(isDeposit, totalAssetsState(isDeposit));
    }

    function assetCollateral() external view returns (address) {
        return address(collateralToken);
    }
}
