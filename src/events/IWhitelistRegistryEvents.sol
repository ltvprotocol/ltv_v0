// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IWhitelistRegistryEvents
 * @notice Interface defining all events used in Whitelist Registry
 */
interface IWhitelistRegistryEvents {
    /**
     * @notice Event emitted when an address is whitelisted or removed from the whitelist
     */
    event AddressWhitelisted(address indexed account, bool isWhitelisted);

    /**
     * @notice Event emitted when the signer is updated
     */
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
}
