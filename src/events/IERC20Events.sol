// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IERC20Events
 * @notice Interface defining all events emitted during ERC20 operations in the LTV vault system
 * @dev This interface contains event definitions for ERC20-related operations,
 *      including transfer and approval events.
 *      These events provide transparency and allow external systems to track ERC20 activities.
 * @author LTV Protocol
 */
interface IERC20Events {
    /**
     * @notice Emitted when tokens are transferred
     * @param from The address sending the tokens
     * @param to The address receiving the tokens
     * @param value The amount of tokens transferred
     * @dev This event is emitted when tokens are transferred from one address to another. Also used
     * to show mint and burn event.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when an approval is granted
     * @param owner The address granting the approval
     * @param spender The address being approved
     * @param value The amount of tokens approved
     * @dev This event is emitted when an approval is granted to a spender
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
