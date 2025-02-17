// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./interfaces/IDummyOracle.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract DummyOracle is IDummyOracle, Ownable {
    mapping(address => uint256) private prices;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external onlyOwner returns (uint256) {
        prices[asset] = price;
        return price;
    }
}