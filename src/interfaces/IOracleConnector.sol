// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IOracleConnector {
    function getPriceCollateralOracle() external view returns (uint256);
    function getPriceBorrowOracle() external view returns (uint256);
}
