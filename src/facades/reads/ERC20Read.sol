// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";

abstract contract ERC20Read is LTVState {
    function totalSupply() external view returns (uint256) {
        return modules.erc20Module().totalSupply(baseTotalSupply);
    }
}
