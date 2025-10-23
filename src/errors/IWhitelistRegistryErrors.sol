// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IWhitelistRegistryErrors
 * @notice Interface defining all custom errors used in Whitelist Registry
 */
interface IWhitelistRegistryErrors {
    /**
     * @notice Error thrown when invalid signature is provided
     */
    error InvalidSignature();
    /**
     * @notice Error thrown when address whitelisting by signature is disabled
     */
    error AddressWhitelistingBySignatureDisabled();
}
