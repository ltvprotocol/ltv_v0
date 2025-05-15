// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './interfaces/IMorphoOracle.sol';
import '../interfaces/IOracleConnector.sol';

contract MorphoOracleConnector is IOracleConnector {
    IMorphoOracle public immutable ORACLE;

    constructor(IMorphoOracle _oracle) {
        ORACLE = _oracle;
    }

    function getPriceCollateralOracle() external view returns (uint256) {
        return ORACLE.price() / 10 ** 18;
    }

    function getPriceBorrowOracle() external pure returns (uint256) {
        return 10 ** 18;
    }
}
