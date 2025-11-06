// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "../../states/LTVState.sol";
import {CommonWrite} from "CommonWrite.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title BorrowVaultWrite
 * @notice This contract contains all the write functions for the borrow vault part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the borrow vault module.
 */

abstract contract BorrowVaultWrite is LTVState, CommonWrite, FacadeImplementationState {
    /**
     * @dev see ILTV.deposit
     */
    function deposit(uint256 assets, address receiver) external returns (uint256) {
        _delegate(address(MODULES.borrowVaultModule()), abi.encode(assets, receiver));
    }

    /**
     * @dev see ILTV.withdraw
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        _delegate(address(MODULES.borrowVaultModule()), abi.encode(assets, receiver, owner));
    }

    /**
     * @dev see ILTV.mint
     */
    function mint(uint256 shares, address receiver) external returns (uint256) {
        _delegate(address(MODULES.borrowVaultModule()), abi.encode(shares, receiver));
    }

    /**
     * @dev see ILTV.redeem
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        _delegate(address(MODULES.borrowVaultModule()), abi.encode(shares, receiver, owner));
    }
}
