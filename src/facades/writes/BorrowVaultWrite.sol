// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract BorrowVaultWrite is ModulesAddressStateReader, CommonWrite {
    function deposit(uint256 assets, address receiver) external returns (uint256) {
        _delegate(getModules().borrowVaultsWrite(), abi.encode(assets, receiver));
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        _delegate(getModules().borrowVaultsWrite(), abi.encode(assets, receiver, owner));
    }

    function mint(uint256 shares, address receiver) external returns (uint256) {
        _delegate(getModules().borrowVaultsWrite(), abi.encode(shares, receiver));
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        _delegate(getModules().borrowVaultsWrite(), abi.encode(shares, receiver, owner));
    }
} 