// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract IOracle {

    function getPriceBorrowOracle() public virtual view returns (uint256);

    function getPriceCollateralOracle() public virtual view returns (uint256);

    function getRealBorrowAssets(bool isDeposit) public virtual view returns (uint256);

    function getRealCollateralAssets(bool isDeposit) public virtual view returns (uint256);
}