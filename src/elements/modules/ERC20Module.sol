// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Approve} from "../../public/erc20/write/Approve.sol";
import {Transfer} from "../../public/erc20/write/Transfer.sol";
import {TransferFrom} from "../../public/erc20/write/TransferFrom.sol";
import {TotalSupply} from "../../public/erc20/read/TotalSupply.sol";

/**
 * @title ERC20Module
 * @notice ERC20 module for LTV protocol
 */
contract ERC20Module is Approve, Transfer, TransferFrom, TotalSupply {
    constructor() {
        _disableInitializers();
    }
}
