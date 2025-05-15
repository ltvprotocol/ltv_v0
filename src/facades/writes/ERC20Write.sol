// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";
import "../writes/CommonWrite.sol";

abstract contract ERC20Write is LTVState, CommonWrite {
    function approve(address spender, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20()), abi.encode(spender, amount));
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20()), abi.encode(to, amount));
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _delegate(address(modules.erc20()), abi.encode(from, to, amount));
    }
}