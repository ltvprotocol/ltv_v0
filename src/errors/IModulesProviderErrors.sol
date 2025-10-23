// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IModulesProviderErrors
 * @notice Interface defining all custom errors used in Modules Provider
 */
interface IModulesProviderErrors {
    /**
     * @notice Error thrown when attempting to set the same address for multiple modules
     * @param duplicateAddress The address that is being used for multiple modules
     * @dev Prevents setting the same contract address for different module types
     */
    error DuplicateModuleAddress(address duplicateAddress);

    /**
     * @notice Error thrown when attempting to set an invalid module address
     * @param moduleAddress The address that is invalid
     * @dev Prevents setting invalid module addresses
     */
    error InvalidModuleAddress(address moduleAddress);
}
