// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IDummyOracle} from "./interfaces/IDummyOracle.sol";

contract DummyOracle is IDummyOracle {
    mapping(address => uint256) private prices;

    constructor() {}

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external returns (uint256) {
        prices[asset] = price;
        return price;
    }
}
