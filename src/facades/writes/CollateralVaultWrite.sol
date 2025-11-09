// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "../../states/LTVState.sol";
import {CommonWrite} from "./CommonWrite.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title CollateralVaultWrite
 * @notice This contract contains all the write functions for the collateral vault part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the collateral vault module.
 */

abstract contract CollateralVaultWrite is LTVState, CommonWrite, FacadeImplementationState {
    /**
     * @dev see ILTV.depositCollateral
     */
    function depositCollateral(uint256 assets, address receiver) external returns (uint256) {
        _delegate(address(MODULES.collateralVaultModule()), abi.encode(assets, receiver));
    }

    /**
     * @dev see ILTV.withdrawCollateral
     */
    function withdrawCollateral(uint256 assets, address receiver, address owner) external returns (uint256) {
        _delegate(address(MODULES.collateralVaultModule()), abi.encode(assets, receiver, owner));
    }

    /**
     * @dev see ILTV.mintCollateral
     */
    function mintCollateral(uint256 shares, address receiver) external returns (uint256) {
        _delegate(address(MODULES.collateralVaultModule()), abi.encode(shares, receiver));
    }

    /**
     * @dev see ILTV.redeemCollateral
     */
    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256) {
        _delegate(address(MODULES.collateralVaultModule()), abi.encode(shares, receiver, owner));
    }
}
