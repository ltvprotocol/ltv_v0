// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IOracleConnector {
    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256);
    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256);

    function initializeOracleConnectorData(bytes calldata oracleConnectorData) external;
}
