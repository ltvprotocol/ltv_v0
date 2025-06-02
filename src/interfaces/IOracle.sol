// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract IOracle {
    function getPriceBorrowOracle() public view virtual returns (uint256);

    function getPriceCollateralOracle() public view virtual returns (uint256);

    function getRealBorrowAssets(bool isDeposit) public view virtual returns (uint256);

    function getRealCollateralAssets(bool isDeposit) public view virtual returns (uint256);
}
