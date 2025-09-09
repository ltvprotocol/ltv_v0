// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IERC20Module
 * @notice Interface defining read functions for the ERC20 module in the LTV vault system
 * @dev This interface contains read functions for the ERC20 part of the LTV protocol
 */
interface IERC20Module {
    /**
     * @dev Module function for ILTV.totalSupply. Also receives cached state for subsequent calculations.
     * Need to abstract it to add virtual supply assets to avoid vault inflation attack
     */
    function totalSupply(uint256 baseTotalSupply) external view returns (uint256);
}
