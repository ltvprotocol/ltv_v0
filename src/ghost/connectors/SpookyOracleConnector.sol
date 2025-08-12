// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../../interfaces/IOracleConnector.sol";
import "../../states/LTVState.sol";
import "../spooky/ISpookyOracle.sol";

contract SpookyOracleConnector is LTVState, IOracleConnector {
    ISpookyOracle public immutable ORACLE;

    constructor(ISpookyOracle _oracle) {
        ORACLE = _oracle;
    }

    function getPriceBorrowOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (, address borrowAsset) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(borrowAsset);
    }

    function getPriceCollateralOracle(bytes calldata oracleConnectorGetterData) external view returns (uint256) {
        (address collateralAsset,) = abi.decode(oracleConnectorGetterData, (address, address));
        return ORACLE.getAssetPrice(collateralAsset);
    }

    function initializeOracleConnectorData(bytes calldata) external {
        oracleConnectorGetterData = abi.encode(address(collateralToken), address(borrowToken));
    }
}
