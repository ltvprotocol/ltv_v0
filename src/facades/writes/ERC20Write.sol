// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract ERC20Write is ModulesAddressStateReader, CommonWrite {
    /// Input - the spender, the amount
    function approve(address /*spender*/, uint256 /*amount*/) external returns (bool) {
        _delegate(getModules().erc20Write());
    }

    /// Input - the receiver, the amount
    function transfer(address /*to*/, uint256 /*amount*/) external returns (bool) {
        _delegate(getModules().erc20Write());
    }

    /// Input - the sender, the receiver, the amount
    function transferFrom(address /*from*/, address /*to*/, uint256 /*amount*/) external returns (bool) {
        _delegate(getModules().erc20Write());
    }
}