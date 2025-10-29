// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IFacadeErrors
 * @notice Interface defining all custom errors used in the LTV vault facade
 */
interface IFacadeErrors {
    /**
     * @notice Error thrown when attempting to set a zero address as modules provider
     * @dev Prevents setting invalid modules provider addresses
     */
    error ZeroModulesProvider();
}
