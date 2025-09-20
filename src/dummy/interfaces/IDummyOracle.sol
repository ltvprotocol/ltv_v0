// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IDummyOracle {
    function getAssetPrice(address asset) external view returns (uint256);

    function setAssetPrice(address asset, uint256 price) external returns (uint256);
}
