// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IDummyLending} from "src/dummy/interfaces/IDummyLending.sol";

contract DummyLending is IDummyLending {
    mapping(address => uint256) internal _supplyBalance;
    mapping(address => uint256) internal _borrowBalance;

    constructor(address initialOwner) {}

    function borrowBalance(address asset) external view returns (uint256) {
        return _borrowBalance[asset];
    }

    function supplyBalance(address asset) external view returns (uint256) {
        return _supplyBalance[asset];
    }

    function borrow(address asset, uint256 amount) external {
        _borrowBalance[asset] += amount;
        IERC20(asset).transfer(msg.sender, amount);
    }

    function repay(address asset, uint256 amount) external {
        require(_borrowBalance[asset] >= amount, "Repay amount exceeds borrow balance");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _borrowBalance[asset] -= amount;
    }

    function supply(address asset, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _supplyBalance[asset] += amount;
    }

    function withdraw(address asset, uint256 amount) external {
        require(_supplyBalance[asset] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(asset).transfer(msg.sender, amount);
        _supplyBalance[asset] -= amount;
    }
}
