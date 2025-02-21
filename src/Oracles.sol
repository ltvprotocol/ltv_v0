// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./Structs.sol";
import "./Constants.sol";

abstract contract Oracles {

    function getPriceBorrowOracle() public virtual view returns (uint256);

    function getPriceCollateralOracle() public virtual view returns (uint256);

    function getRealBorrowAssets() public virtual view returns (uint256);

    function getRealCollateralAssets() public virtual view returns (uint256);

}