// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IMorphoOracle} from "src/connectors/oracle_connectors/interfaces/IMorphoOracle.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title MorphoOracleConnector
 * @notice Connector for Morpho Oracle
 */
contract MorphoOracleConnector is LTVState, IOracleConnector {
    IMorphoOracle public immutable ORACLE;

    constructor(IMorphoOracle _oracle) {
        ORACLE = _oracle;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceCollateralOracle(bytes calldata oracleConnectorData) external view returns (uint256) {
        (, uint8 collateralTokenDecimals) = abi.decode(oracleConnectorData, (uint8, uint8));
        return ORACLE.price() / 10 ** collateralTokenDecimals;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceBorrowOracle(bytes calldata oracleConnectorData) external view returns (uint256) {
        (uint8 borrowTokenDecimals,) = abi.decode(oracleConnectorData, (uint8, uint8));
        return 10 ** borrowTokenDecimals;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function initializeOracleConnectorData(bytes calldata) external {
        oracleConnectorGetterData = abi.encode(borrowTokenDecimals, collateralTokenDecimals);
    }
}
