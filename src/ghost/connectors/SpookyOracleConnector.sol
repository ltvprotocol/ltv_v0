// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../../interfaces/IOracleConnector.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../spooky/ISpookyOracle.sol";

contract SpookyOracleConnector is IOracleConnector {
    ISpookyOracle public immutable ORACLE;

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;

    constructor(IERC20 _collateralToken, IERC20 _borrowToken, ISpookyOracle _oracle) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        ORACLE = _oracle;
    }

    function getPriceBorrowOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(address(BORROW_TOKEN));
    }

    function getPriceCollateralOracle() external view returns (uint256) {
        return ORACLE.getAssetPrice(address(COLLATERAL_TOKEN));
    }
}
