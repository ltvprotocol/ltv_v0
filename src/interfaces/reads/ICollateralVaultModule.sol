// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";

interface ICollateralVaultModule {
    function previewDepositCollateral(uint256 assets, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    function previewWithdrawCollateral(uint256 assets, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    function previewMintCollateral(uint256 shares, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    function previewRedeemCollateral(uint256 shares, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    function maxDepositCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState)
        external
        view
        returns (uint256);

    function maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState)
        external
        view
        returns (uint256);

    function maxMintCollateral(MaxDepositMintCollateralVaultState memory maxDepositMintCollateralVaultState)
        external
        view
        returns (uint256);

    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory maxWithdrawRedeemCollateralVaultState)
        external
        view
        returns (uint256);

    function convertToSharesCollateral(uint256 assets, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    function convertToAssetsCollateral(uint256 shares, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    function totalAssetsCollateral(TotalAssetsState memory totalAssetsState) external view returns (uint256);

    function totalAssetsCollateral(bool isDeposit, TotalAssetsState memory totalAssetsState)
        external
        view
        returns (uint256);
}
