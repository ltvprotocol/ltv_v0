// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

/**
 * @title ERC20Write
 * @notice This contract contains all the write functions for the ERC20 part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the ERC20 module.
 */
abstract contract ERC20Write is LTVState, CommonWrite {
    function approve(address spender, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20Module()), abi.encode(spender, amount));
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20Module()), abi.encode(to, amount));
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20Module()), abi.encode(from, to, amount));
    }
}
