// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../structs/state/vault/PreviewDepositVaultState.sol";
import "../../structs/state/vault/PreviewWithdrawVaultState.sol";
import "../../structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import "../../structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import "../../structs/state/MaxGrowthFeeState.sol";
import "../../structs/state/vault/TotalAssetsState.sol";

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
