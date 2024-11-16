// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Structs.sol";
import "./Constants.sol";

abstract contract Oracles {

    function getPriceBorrowOracle() public view returns (uint256) {
        // TODO:
        // go to oracle
        return Constants.ORACLE_DEVIDER;
    }

    function getPriceCollateralOracle() public view returns (uint256) {
        // TODO:
        // go to oracle
        return Constants.ORACLE_DEVIDER;
    }

    function getRealBorrowAssets() public view returns (uint256) {
        // TODO:
        // go to lending protocol
        return 0;
    }

    function getRealCollateralAssets() public view returns (uint256) {
        // TODO:
        // go to lending protocol
        return 0;
    }

    function getPrices() internal view returns (Prices memory) {
        return Prices({
            borrow: getPriceBorrowOracle(),
            collateral: getPriceCollateralOracle(),
            borrowSlippage: 0,
            collateralSlippage: 0
        });
    }

}