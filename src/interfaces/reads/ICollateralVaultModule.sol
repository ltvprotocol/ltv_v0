// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";

/**
 * @title ICollateralVaultModule
 * @notice Interface defining all read functions for the collateral vault module in the LTV vault system
 * @dev This interface contains read functions for the collateral vault part of the LTV protocol
 */
interface ICollateralVaultModule {
    /**
     * @dev Module function for ILTV.previewDepositCollateral. Also receives cached state for subsequent calculations.
     */
    function previewDepositCollateral(uint256 assets, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewWithdrawCollateral. Also receives cached state for subsequent calculations.
     */
    function previewWithdrawCollateral(uint256 assets, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewMintCollateral. Also receives cached state for subsequent calculations.
     */
    function previewMintCollateral(uint256 shares, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewRedeemCollateral. Also receives cached state for subsequent calculations.
     */
    function previewRedeemCollateral(uint256 shares, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxDepositCollateral. Also receives cached state for subsequent calculations.
     */
    function maxDepositCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxWithdrawCollateral. Also receives cached state for subsequent calculations.
     */
    function maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxMintCollateral. Also receives cached state for subsequent calculations.
     */
    function maxMintCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxRedeemCollateral. Also receives cached state for subsequent calculations.
     */
    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.convertToSharesCollateral. Also receives cached state for subsequent calculations.
     */
    function convertToSharesCollateral(uint256 assets, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.convertToAssetsCollateral. Also receives cached state for subsequent calculations.
     */
    function convertToAssetsCollateral(uint256 shares, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.totalAssetsCollateral. Also receives cached state for subsequent calculations.
     */
    function totalAssetsCollateral(TotalAssetsState memory totalAssetsState) external view returns (uint256);

    /**
     * @dev Module function for ILTV.totalAssetsCollateral. Also receives cached state for subsequent calculations.
     */
    function totalAssetsCollateral(bool isDeposit, TotalAssetsState memory totalAssetsState)
        external
        view
        returns (uint256);
}
