// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IOracleConnector
 * @notice Interface defines connector structure for integration with LTV protocol.
 */
interface IOracleConnector {
    /**
     * @dev Get the price of the collateral asset
     */
    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256);

    /**
     * @dev Get the price of the borrow asset
     */
    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256);

    /**
     * @dev Initialize the oracle connector data for next calls of getters.
     */
    function initializeOracleConnectorData(bytes calldata oracleConnectorData) external;
}
