// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IMorphoOracleConnectorErrors
 * @notice Interface defining all custom errors used in Morpho Oracle Connector
 */
interface IMorphoOracleConnectorErrors {
    /**
     * @notice Error thrown when oracle address is zero
     */
    error ZeroOracleAddress();
}
