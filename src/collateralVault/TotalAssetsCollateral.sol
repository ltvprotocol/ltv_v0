// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../borrowVault/TotalAssets.sol';

abstract contract TotalAssetsCollateral is TotalAssets {

    using uMulDiv for uint256;
    function totalAssetsCollateral() public view returns (uint256) {
        return totalAssets().mulDivDown(getPriceBorrowOracle(), getPriceCollateralOracle());
    }
}