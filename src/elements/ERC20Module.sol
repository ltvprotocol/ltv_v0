// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ERC20WriteImpl} from "src/public/erc20/ERC20WriteImpl.sol";
import {TotalSupply} from "src/public/erc20/TotalSupply.sol";

/**
 * @title ERC20Module
 * @notice ERC20 module for LTV protocol
 */
contract ERC20Module is ERC20WriteImpl, TotalSupply {
    constructor() {
        _disableInitializers();
    }
}
