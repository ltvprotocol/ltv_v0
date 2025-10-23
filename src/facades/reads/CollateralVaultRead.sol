// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultStateReader} from
    "src/state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxWithdrawRedeemCollateralVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title CollateralVaultRead
 * @notice This contract contains all the read functions for the collateral vault part of the LTV protocol.
 * It retrieves appropriate function state and delegates all the calculations to the collateral vault module.
 */

abstract contract CollateralVaultRead is
    MaxDepositMintCollateralVaultStateReader,
    MaxWithdrawRedeemCollateralVaultStateReader,
    FacadeImplementationState
{
    /**
     * @dev see ILTV.previewDepositCollateral
     */
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return MODULES.collateralVaultModule().previewDepositCollateral(assets, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewWithdrawCollateral
     */
    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return MODULES.collateralVaultModule().previewWithdrawCollateral(assets, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.previewMintCollateral
     */
    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return MODULES.collateralVaultModule().previewMintCollateral(shares, previewDepositVaultState());
    }

    /**
     * @dev see ILTV.previewRedeemCollateral
     */
    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return MODULES.collateralVaultModule().previewRedeemCollateral(shares, previewWithdrawVaultState());
    }

    /**
     * @dev see ILTV.maxDepositCollateral
     */
    function maxDepositCollateral(address) external view returns (uint256) {
        return MODULES.collateralVaultModule().maxDepositCollateral(maxDepositMintCollateralVaultState());
    }

    /**
     * @dev see ILTV.maxWithdrawCollateral
     */
    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return MODULES.collateralVaultModule().maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    /**
     * @dev see ILTV.maxMintCollateral
     */
    function maxMintCollateral(address) external view returns (uint256) {
        return MODULES.collateralVaultModule().maxMintCollateral(maxDepositMintCollateralVaultState());
    }

    /**
     * @dev see ILTV.maxRedeemCollateral
     */
    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return MODULES.collateralVaultModule().maxRedeemCollateral(maxWithdrawRedeemCollateralVaultState(owner));
    }

    /**
     * @dev see ILTV.convertToSharesCollateral
     */
    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return MODULES.collateralVaultModule().convertToSharesCollateral(assets, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.convertToAssetsCollateral
     */
    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return MODULES.collateralVaultModule().convertToAssetsCollateral(shares, maxGrowthFeeState());
    }

    /**
     * @dev see ILTV.totalAssetsCollateral
     */
    function totalAssetsCollateral() external view returns (uint256) {
        return MODULES.collateralVaultModule().totalAssetsCollateral(totalAssetsState(false));
    }

    /**
     * @dev see ILTV.totalAssetsCollateral
     */
    function totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return MODULES.collateralVaultModule().totalAssetsCollateral(isDeposit, totalAssetsState(isDeposit));
    }

    function assetCollateral() external view returns (address) {
        return address(collateralToken);
    }
}
