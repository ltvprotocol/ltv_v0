// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import 'src/state_reader/PreviewVaultStateReader.sol';
import 'src/state_reader/MaxDepositMintBorrowVaultStateReader.sol';
import 'src/state_reader/MaxWithdrawRedeemBorrowVaultStateReader.sol';

abstract contract BorrowVaultRead is PreviewVaultStateReader, MaxDepositMintBorrowVaultStateReader, MaxWithdrawRedeemBorrowVaultStateReader {
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewDeposit(assets, previewVaultState());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().previewWithdraw(assets, previewVaultState());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewMint(shares, previewVaultState());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().previewRedeem(shares, previewVaultState());
    }

    function maxDeposit(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxDeposit(maxDepositMintBorrowVaultState());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxWithdraw(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function maxMint(address) external view returns (uint256) {
        return modules.borrowVaultModule().maxMint(maxDepositMintBorrowVaultState());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return modules.borrowVaultModule().maxRedeem(maxWithdrawRedeemBorrowVaultState(owner));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return modules.borrowVaultModule().convertToShares(assets, maxGrowthFeeState());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return modules.borrowVaultModule().convertToAssets(shares, maxGrowthFeeState());
    }

    function totalAssets() external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(totalAssetsState());
    }

    function totalAssets(bool isDeposit) external view returns (uint256) {
        return modules.borrowVaultModule().totalAssets(isDeposit, totalAssetsState());
    }
}
