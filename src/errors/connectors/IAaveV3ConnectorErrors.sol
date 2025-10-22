// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAaveV3ConnectorErrors
 * @notice Interface defining all custom errors used in Aave V3 Connector
 */
interface IAaveV3ConnectorErrors {
    /**
     * @notice Error thrown when pool address is zero
     */
    error ZeroPoolAddress();
    /**
     * @notice Error thrown when E-Mode ID is invalid
     */
    error InvalidEModeId(uint8 emodeId);
    /**
     * @notice Error thrown when collateral token is unsupported by aave v3 pool
     */
    error UnsupportedCollateralToken(address token);
    /**
     * @notice Error thrown when borrow token is unsupported by aave v3 pool
     */
    error UnsupportedBorrowToken(address token);
}
