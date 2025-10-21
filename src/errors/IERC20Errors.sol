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
    error ERC20TransferToZeroAddress();
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

    /**
     * @notice Error thrown when approving to zero address
     * @dev Prevents approving to zero address
     */
    error ERC20ApproveToZeroAddress();

    /**
     * @notice Error thrown when token owner has insufficient balance to perform the requested operation
     */
    error ERC20InsufficientBalance(address owner, uint256 ownerBalance, uint256 needed);

    /**
     * @notice Error thrown when trying to mint tokens to zero address
     */
    error ERC20MintToZeroAddress();
}
