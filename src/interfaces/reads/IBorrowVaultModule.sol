// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";

/**
 * @title IBorrowVaultModule
 * @notice Interface defining all read functions for the borrow vault module in the LTV vault system
 * @dev This interface contains read functions for the borrow vault part of the LTV protocol
 */
interface IBorrowVaultModule {
    /**
     * @dev Module function for ILTV.previewDeposit. Also receives cached state for subsequent calculations.
     */
    function previewDeposit(uint256 assets, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewWithdraw. Also receives cached state for subsequent calculations.
     */
    function previewWithdraw(uint256 assets, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewMint. Also receives cached state for subsequent calculations.
     */
    function previewMint(uint256 shares, PreviewDepositVaultState memory previewDepositVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.previewRedeem. Also receives cached state for subsequent calculations.
     */
    function previewRedeem(uint256 shares, PreviewWithdrawVaultState memory previewWithdrawVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxDeposit. Also receives cached state for subsequent calculations.
     */
    function maxDeposit(MaxDepositMintBorrowVaultState memory maxDepositMintBorrowVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxWithdraw. Also receives cached state for subsequent calculations.
     */
    function maxWithdraw(MaxWithdrawRedeemBorrowVaultState memory maxWithdrawRedeemBorrowVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxMint. Also receives cached state for subsequent calculations.
     */
    function maxMint(MaxDepositMintBorrowVaultState memory maxDepositMintBorrowVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.maxRedeem. Also receives cached state for subsequent calculations.
     */
    function maxRedeem(MaxWithdrawRedeemBorrowVaultState memory maxWithdrawRedeemBorrowVaultState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.convertToShares. Also receives cached state for subsequent calculations.
     */
    function convertToShares(uint256 assets, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.convertToAssets. Also receives cached state for subsequent calculations.
     */
    function convertToAssets(uint256 shares, MaxGrowthFeeState memory maxGrowthFeeState)
        external
        view
        returns (uint256);

    /**
     * @dev Module function for ILTV.totalAssets. Also receives cached state for subsequent calculations.
     */
    function totalAssets(TotalAssetsState memory totalAssetsState) external view returns (uint256);

    /**
     * @dev Module function for ILTV.totalAssets. Also receives cached state for subsequent calculations.
     */
    function totalAssets(bool isDeposit, TotalAssetsState memory totalAssetsState) external view returns (uint256);

    function asset() external view returns (address assetTokenAddress);
}
