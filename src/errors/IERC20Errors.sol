// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IERC20Errors
 * @notice Interface defining all custom errors used in ERC20 operations
 * @dev This interface contains error definitions for ERC20 operations
 *      that help maintain ERC20 operations
 */
interface IERC20Errors {
    /**
     * @notice Error thrown when transferring to zero address
     * @dev Prevents transferring to zero address
     */
    error TransferToZeroAddress();
    /**
     * @notice Error thrown when ERC20 insufficient allowance
     */
    /**
     * @notice Error thrown when ERC20 insufficient allowance
     * @param spender The address of the spender
     * @param allowance The allowance of the spender
     * @param needed The needed allowance
     * @dev Prevents spending more than allowed
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
}
