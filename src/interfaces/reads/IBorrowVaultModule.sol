// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";

interface IBorrowVaultModule {
    function previewDeposit(uint256 assets, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    function previewWithdraw(uint256 assets, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    function previewMint(uint256 shares, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    function previewRedeem(uint256 shares, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    function maxDeposit(MaxDepositMintBorrowVaultState memory maxDepositMintBorrowVaultState)
        external
        view
        returns (uint256);

    function maxWithdraw(MaxWithdrawRedeemBorrowVaultState memory maxWithdrawRedeemBorrowVaultState)
        external
        view
        returns (uint256);

    function maxMint(MaxDepositMintBorrowVaultState memory maxDepositMintBorrowVaultState)
        external
        view
        returns (uint256);

    function maxRedeem(MaxWithdrawRedeemBorrowVaultState memory maxWithdrawRedeemBorrowVaultState)
        external
        view
        returns (uint256);

    function convertToShares(uint256 assets, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    function convertToAssets(uint256 shares, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    function totalAssets(TotalAssetsState memory totalAssetsState) external view returns (uint256);

    function totalAssets(bool isDeposit, TotalAssetsState memory totalAssetsState) external view returns (uint256);
}
