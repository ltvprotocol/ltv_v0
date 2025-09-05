// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IWhitelistRegistry
 * @notice Interface defines whitelist registry function needed to be implemented to work with LTV protocol.
 */
interface IWhitelistRegistry {
    /**
     * @dev Check if the address is whitelisted
     */
    function isAddressWhitelisted(address account) external view returns (bool);
}
