// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

/**
 * @title CollateralVaultWrite
 * @notice This contract contains all the write functions for the collateral vault part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the collateral vault module.
 */
abstract contract CollateralVaultWrite is LTVState, CommonWrite {
    function depositCollateral(uint256 assets, address receiver) external returns (uint256) {
        _delegate(address(modules.collateralVaultModule()), abi.encode(assets, receiver));
    }

    function withdrawCollateral(uint256 assets, address receiver, address owner) external returns (uint256) {
        _delegate(address(modules.collateralVaultModule()), abi.encode(assets, receiver, owner));
    }

    function mintCollateral(uint256 shares, address receiver) external returns (uint256) {
        _delegate(address(modules.collateralVaultModule()), abi.encode(shares, receiver));
    }

    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256) {
        _delegate(address(modules.collateralVaultModule()), abi.encode(shares, receiver, owner));
    }
}
