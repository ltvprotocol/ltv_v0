// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";

/**
 * @title ERC20Read
 * @notice This contract contains totalSupply function of the LTV protocol. All the other
 * ERC20 functions are handled by the LTVState.
 */
abstract contract ERC20Read is LTVState {
    function totalSupply() external view returns (uint256) {
        return modules.erc20Module().totalSupply(baseTotalSupply);
    }
}
