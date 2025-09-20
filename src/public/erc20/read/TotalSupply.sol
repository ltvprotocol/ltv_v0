// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";

/**
 * @title TotalSupply
 * @notice This contract contains totalSupply function implementation.
 */
abstract contract TotalSupply {
    /**
     * @dev see IERC20Module.totalSupply
     */
    function totalSupply(uint256 supply) public pure virtual returns (uint256) {
        // add 100 to avoid vault inflation attack
        return supply + Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
