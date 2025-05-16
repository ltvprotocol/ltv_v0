// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../structs/state/vault/PreviewVaultState.sol';
import '../../structs/state/vault/MaxDepositMintCollateralVaultState.sol';
import '../../structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol';
import '../../structs/state/MaxGrowthFeeState.sol';
import '../../structs/state/vault/TotalAssetsState.sol';

interface ICollateralVaultModule {
    function previewDepositCollateral(uint256 assets, PreviewVaultState memory previewVaultState) external view returns (uint256);

    function previewWithdrawCollateral(uint256 assets, PreviewVaultState memory previewVaultState) external view returns (uint256);

    function previewMintCollateral(uint256 shares, PreviewVaultState memory previewVaultState) external view returns (uint256);

    function previewRedeemCollateral(uint256 shares, PreviewVaultState memory previewVaultState) external view returns (uint256);

    function maxDepositCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState) external view returns (uint256);

    function maxWithdrawCollateral(
        MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState
    ) external view returns (uint256);

    function maxMintCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState) external view returns (uint256);

    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState) external view returns (uint256);

    function convertToSharesCollateral(uint256 assets, MaxGrowthFeeState memory maxGrowthFeeState) external view returns (uint256);

    function convertToAssetsCollateral(uint256 shares, MaxGrowthFeeState memory maxGrowthFeeState) external view returns (uint256);

    function totalAssetsCollateral(TotalAssetsState memory totalAssetsState) external view returns (uint256);

    function totalAssetsCollateral(bool isDeposit, TotalAssetsState memory totalAssetsState) external view returns (uint256);
}
