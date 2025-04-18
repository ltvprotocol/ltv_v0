// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../../states/readers/ApplicationStateReader.sol";

abstract contract CollateralVaultRead is ApplicationStateReader, ModulesAddressStateReader {
    function previewDepositCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewDepositCollateral(assets, getStateRepresentation());
    }

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewWithdrawCollateral(assets, getStateRepresentation());
    }

    function previewMintCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewMintCollateral(shares, getStateRepresentation());
    }

    function previewRedeemCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().previewRedeemCollateral(shares, getStateRepresentation());
    }

    function maxDepositCollateral(address receiver) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxDepositCollateral(receiver, getStateRepresentation());
    }

    function maxWithdrawCollateral(address owner) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxWithdrawCollateral(owner, getStateRepresentation());
    }

    function maxMintCollateral(address receiver) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxMintCollateral(receiver, getStateRepresentation());
    }

    function maxRedeemCollateral(address owner) external view returns (uint256) {
        return getModules().collateralVaultsRead().maxRedeemCollateral(owner, getStateRepresentation());
    }

    function convertToSharesCollateral(uint256 assets) external view returns (uint256) {
        return getModules().collateralVaultsRead().convertToSharesCollateral(assets, getStateRepresentation());
    }

    function convertToAssetsCollateral(uint256 shares) external view returns (uint256) {
        return getModules().collateralVaultsRead().convertToAssetsCollateral(shares, getStateRepresentation());
    }
    
    function totalAssetsCollateral() external view returns (uint256) {
        return getModules().collateralVaultsRead().totalAssetsCollateral(getStateRepresentation());
    }
    
    function _totalAssetsCollateral(bool isDeposit) external view returns (uint256) {
        return getModules().collateralVaultsRead()._totalAssetsCollateral(isDeposit, getStateRepresentation());
    }
} 