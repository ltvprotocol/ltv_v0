// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IMorphoOracleConnectorErrors
 * @notice Interface defining all custom errors used in Morpho Oracle Connector
 */
interface IMorphoConnectorErrors {
    /**
     * @notice Error thrown when morpho address is zero
     */
    error ZeroMorphoAddress();

    /**
     * @notice Error thrown when LLTv market param is zero
     */
    error ZeroLltvMarketParam();
    /**
     * @notice Error thrown when oracle market param is zero
     */
    error ZeroOracleMarketParam();
    /**
     * @notice Error thrown when IRM market param is zero
     */
    error ZeroIrmMarketParam();

    /**
     * @notice Error thrown when loan token market param is zero
     */
    error ZeroLoanTokenMarketParam();
    /**
     * @notice Error thrown when collateral token market param is zero
     */
    error ZeroCollateralTokenMarketParam();

    /**
     * @notice Error thrown when provided oracle address doesn't correspond
     * to provided marketId
     */
    error InvalidOracle(address provided, address fetched);
    /**
     * @notice Error thrown when provided IRM address doesn't correspond
     * to provided marketId
     */
    error InvalidIrm(address provided, address fetched);
    /**
     * @notice Error thrown when provided lltv doesn't correspond
     * to marketId
     */
    error InvalidLltv(uint256 provided, uint256 fetched);

    /**
     * @notice Error thrown when provided collateral token address doesn't correspond
     * to provided marketId
     */
    error InvalidCollateralToken(address provided, address fetched);
    /**
     * @notice Error thrown when provided loan token address doesn't correspond
     * to provided marketId
     */
    error InvalidLoanToken(address provided, address fetched);
}
