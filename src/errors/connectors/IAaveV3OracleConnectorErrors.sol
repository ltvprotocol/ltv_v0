// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAaveV3OracleConnectorErrors
 * @notice Interface defining all custom errors used in Aave V3 Oracle Connector
 */
interface IAaveV3OracleConnectorErrors {
    /**
     * @notice Error thrown when oracle address is zero
     */
    error ZeroOracleAddress();

    /**
     * @notice Error thrown when no source of asset price is found
     */
    error NoSourceOfAssetPrice(address asset);
}
