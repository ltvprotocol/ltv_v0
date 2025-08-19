// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

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
