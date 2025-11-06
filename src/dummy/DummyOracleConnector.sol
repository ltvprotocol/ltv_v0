// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IOracleConnector} from "../interfaces/connectors/IOracleConnector.sol";
import {IDummyOracle} from "./interfaces/IDummyOracle.sol";
import {LTVState} from "../states/LTVState.sol";

contract DummyOracleConnector is LTVState, IOracleConnector {
    IDummyOracle public immutable ORACLE;

    constructor(IDummyOracle _oracle) {
        ORACLE = _oracle;
    }

    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view override returns (uint256) {
        (, address borrowAsset) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(borrowAsset);
    }

    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData)
        external
        view
        override
        returns (uint256)
    {
        (address collateralAsset,) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(collateralAsset);
    }

    function initializeOracleConnectorData(bytes calldata) external {
        oracleConnectorGetterData = abi.encode(address(collateralToken), address(borrowToken));
    }
}
