// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract SpookyOracle is Initializable, OwnableUpgradeable {
    mapping(address => uint256) private prices;

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external onlyOwner returns (uint256) {
        prices[asset] = price;
        return price;
    }
}
