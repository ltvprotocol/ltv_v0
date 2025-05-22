// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './interfaces/IAaveOracle.sol';
import '../../interfaces/IOracleConnector.sol';

contract AaveV3OracleConnector is IOracleConnector {
    IAaveOracle public constant ORACLE = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);
    address public immutable COLLATERAL_ASSET;
    address public immutable BORROW_ASSET;

    constructor(address _collateralAsset, address _borrowAsset) {
        COLLATERAL_ASSET = _collateralAsset;
        BORROW_ASSET = _borrowAsset;
    }

    function getPriceCollateralOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(COLLATERAL_ASSET);
    }

    function getPriceBorrowOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(BORROW_ASSET);
    }
}