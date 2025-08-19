// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "src/interfaces/IOracleConnector.sol";
import {IAaveOracle} from "src/connectors/oracle_connectors/interfaces/IAaveOracle.sol";
import {LTVState} from "src/states/LTVState.sol";

contract AaveV3OracleConnector is LTVState, IOracleConnector {
    IAaveOracle public constant ORACLE = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);

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