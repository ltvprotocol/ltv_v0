// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title ERC20Read
 * @notice This contract contains totalSupply function of the LTV protocol. All the other
 * ERC20 functions are handled by the LTVState.
 */
abstract contract ERC20Read is LTVState, FacadeImplementationState {
    /**
     * @dev see ILTV.totalSupply
     */
    function totalSupply() external view returns (uint256) {
        return MODULES.erc20Module().totalSupply(baseTotalSupply);
    }
}
