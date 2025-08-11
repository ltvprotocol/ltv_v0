// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./interfaces/IAaveOracle.sol";
import "../../interfaces/IOracleConnector.sol";

contract AaveV3OracleConnector is IOracleConnector {
    IAaveOracle public immutable ORACLE;
    address public immutable COLLATERAL_ASSET;
    address public immutable BORROW_ASSET;

    constructor(address _collateralAsset, address _borrowAsset, address _oracle) {
        COLLATERAL_ASSET = _collateralAsset;
        BORROW_ASSET = _borrowAsset;
        ORACLE = IAaveOracle(_oracle);
    }

    function getPriceCollateralOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(COLLATERAL_ASSET);
    }

    function getPriceBorrowOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(BORROW_ASSET);
    }
}
