// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IAaveV3Oracle} from "src/connectors/oracle_connectors/interfaces/IAaveV3Oracle.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title AaveV3OracleConnector
 * @notice Connector for Aave V3 Oracle
 */
contract AaveV3OracleConnector is LTVState, IOracleConnector {
    /**
     * @notice Error thrown when oracle address is zero
     */
    error ZeroOracleAddress();

    /**
     * @notice Error thrown when no source of asset price is found
     */
    error NoSourceOfAssetPrice(address asset);

    IAaveV3Oracle public immutable ORACLE;

    constructor(address _oracle) {
        require(_oracle != address(0), ZeroOracleAddress());
        ORACLE = IAaveV3Oracle(_oracle);
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (address collateralAsset,) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(collateralAsset) * 10 ** 10;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (, address borrowAsset) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(borrowAsset) * 10 ** 10;
    }

    /**
     * @inheritdoc IOracleConnector
     */
    function initializeOracleConnectorData(bytes calldata) external {
        oracleConnectorGetterData = abi.encode(address(collateralToken), address(borrowToken));
        require(
            ORACLE.getSourceOfAsset(address(collateralToken)) != address(0),
            NoSourceOfAssetPrice(address(collateralToken))
        );
        require(ORACLE.getSourceOfAsset(address(borrowToken)) != address(0), NoSourceOfAssetPrice(address(borrowToken)));
    }
}
