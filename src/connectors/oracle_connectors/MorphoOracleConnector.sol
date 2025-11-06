// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "../../interfaces/connectors/IOracleConnector.sol";
import {IMorphoOracle} from "./interfaces/IMorphoOracle.sol";
import {IMorphoBlue} from "../lending_connectors/interfaces/IMorphoBlue.sol";
import {LTVState} from "../../states/LTVState.sol";
import {IMorphoConnectorErrors} from "../../../src/errors/connectors/IMorphoConnectorErrors.sol";

/**
 * @title MorphoOracleConnector
 * @notice Connector for Morpho Oracle
 */
contract MorphoOracleConnector is LTVState, IOracleConnector, IMorphoConnectorErrors {
    IMorphoBlue public immutable MORPHO;

    constructor(address _morpho) {
        require(_morpho != address(0), ZeroMorphoAddress());
        MORPHO = IMorphoBlue(_morpho);
    }

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
    function initializeOracleConnectorData(bytes calldata data) external {
        (address oracle, bytes32 marketId) = abi.decode(data, (address, bytes32));
        (address fetchedLoanToken, address fetchedCollateralToken, address fetchedOracle,,) =
            MORPHO.idToMarketParams(marketId);

        require(fetchedOracle != address(0), ZeroOracleMarketParam());
        require(fetchedOracle == oracle, InvalidOracle(oracle, fetchedOracle));
        require(fetchedLoanToken == address(borrowToken), InvalidLoanToken(address(borrowToken), fetchedLoanToken));
        require(
            fetchedCollateralToken == address(collateralToken),
            InvalidCollateralToken(address(collateralToken), fetchedCollateralToken)
        );

        oracleConnectorGetterData = abi.encode(borrowTokenDecimals, collateralTokenDecimals, oracle);
    }
}
