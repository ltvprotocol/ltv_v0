// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IMorphoOracle} from "src/connectors/oracle_connectors/interfaces/IMorphoOracle.sol";
import {LTVState} from "src/states/LTVState.sol";
import {IMorphoOracleConnectorErrors} from "../../../src/errors/connectors/IMorphoOracleConnectorErrors.sol";

/**
 * @title MorphoOracleConnector
 * @notice Connector for Morpho Oracle
 */
contract MorphoOracleConnector is LTVState, IOracleConnector, IMorphoOracleConnectorErrors {
    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceCollateralOracle(bytes calldata oracleConnectorData) external view returns (uint256) {
        (, uint8 collateralTokenDecimals, address oracle) = abi.decode(oracleConnectorData, (uint8, uint8, address));
        return IMorphoOracle(oracle).price() / 10 ** (36 - collateralTokenDecimals);
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceBorrowOracle(bytes calldata oracleConnectorData) external pure returns (uint256) {
        (uint8 borrowTokenDecimals,,) = abi.decode(oracleConnectorData, (uint8, uint8, address));
        return 10 ** borrowTokenDecimals;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function initializeOracleConnectorData(bytes calldata _oracle) external {
        address oracle = abi.decode(_oracle, (address));
        require(oracle != address(0), ZeroOracleAddress());
        oracleConnectorGetterData = abi.encode(borrowTokenDecimals, collateralTokenDecimals, oracle);
    }
}
