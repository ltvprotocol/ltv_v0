// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IOracleConnector} from "src/interfaces/IOracleConnector.sol";
import {IDummyOracle} from "src/dummy/interfaces/IDummyOracle.sol";

contract DummyOracleConnector is IOracleConnector {
    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;
    IDummyOracle public immutable ORACLE;

    constructor(IERC20 _collateralToken, IERC20 _borrowToken, IDummyOracle _oracle) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        ORACLE = _oracle;
    }

    function getPriceBorrowOracle() external view override returns (uint256) {
        return ORACLE.getAssetPrice(address(BORROW_TOKEN));
    }

    function getPriceCollateralOracle() external view override returns (uint256) {
        return ORACLE.getAssetPrice(address(COLLATERAL_TOKEN));
    }
}
