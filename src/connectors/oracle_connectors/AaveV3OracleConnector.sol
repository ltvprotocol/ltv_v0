// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IAaveV3Oracle} from "src/connectors/oracle_connectors/interfaces/IAaveV3Oracle.sol";
import {LTVState} from "src/states/LTVState.sol";

contract AaveV3OracleConnector is LTVState, IOracleConnector {
    IAaveV3Oracle public immutable ORACLE;

    constructor(address _oracle) {
        ORACLE = IAaveV3Oracle(_oracle);
    }

    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (address collateralAsset,) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(collateralAsset) * 10 ** 10;
    }

    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (, address borrowAsset) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(borrowAsset) * 10 ** 10;
    }

    function initializeOracleConnectorData(bytes calldata) external {
        oracleConnectorGetterData = abi.encode(address(collateralToken), address(borrowToken));
    }
}
