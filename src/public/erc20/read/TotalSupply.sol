// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "../../../constants/Constants.sol";
import {NonReentrantRead} from "../../../modifiers/NonReentrantRead.sol";

/**
 * @title TotalSupply
 * @notice This contract contains totalSupply function implementation.
 */
abstract contract TotalSupply is NonReentrantRead {
    /**
     * @dev see IERC20Module.totalSupply
     */
    function totalSupply(uint256 supply) external view nonReentrantRead returns (uint256) {
        return _totalSupply(supply);
    }

    function _totalSupply(uint256 supply) internal pure virtual returns (uint256) {
        // add virtual assets to avoid vault inflation attack
        return supply + Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
