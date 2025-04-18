// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract CollateralVaultWrite is ModulesAddressStateReader, CommonWrite {
    function depositCollateral(uint256 assets, address receiver) external returns (uint256) {
        _delegate(getModules().collateralVaultsWrite(), abi.encode(assets, receiver));
    }

    function withdrawCollateral(uint256 assets, address receiver, address owner) external returns (uint256) {
        _delegate(getModules().collateralVaultsWrite(), abi.encode(assets, receiver, owner));
    }

    function mintCollateral(uint256 shares, address receiver) external returns (uint256) {
        _delegate(getModules().collateralVaultsWrite(), abi.encode(shares, receiver));
    }

    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256) {
        _delegate(getModules().collateralVaultsWrite(), abi.encode(shares, receiver, owner));
    }
} 