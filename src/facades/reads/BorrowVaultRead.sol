// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../../states/readers/ApplicationStateReader.sol";

abstract contract BorrowVaultRead is ApplicationStateReader, ModulesAddressStateReader {
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewDeposit(assets, getStateRepresentation());
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewWithdraw(assets, getStateRepresentation());
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewMint(shares, getStateRepresentation());
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().previewRedeem(shares, getStateRepresentation());
    }

    function maxDeposit(address receiver) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxDeposit(receiver, getStateRepresentation());
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxWithdraw(owner, getStateRepresentation());
    }

    function maxMint(address receiver) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxMint(receiver, getStateRepresentation());
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return getModules().borrowVaultsRead().maxRedeem(owner, getStateRepresentation());
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return getModules().borrowVaultsRead().convertToShares(assets, getStateRepresentation());
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return getModules().borrowVaultsRead().convertToAssets(shares, getStateRepresentation());
    }
    
    function totalAssets() external view returns (uint256) {
        return getModules().borrowVaultsRead().totalAssets(getStateRepresentation());
    }
    
    function _totalAssets(bool isDeposit) external view returns (uint256) {
        return getModules().borrowVaultsRead()._totalAssets(isDeposit, getStateRepresentation());
    }
} 