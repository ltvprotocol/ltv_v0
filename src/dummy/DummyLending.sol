// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './interfaces/IDummyLending.sol';
import '../utils/Ownable.sol';

contract DummyLending is IDummyLending, Ownable {
    mapping(address => uint256) public supplyBalance;
    mapping(address => uint256) public borrowBalance;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function borrow(address asset, uint256 amount) external onlyOwner {
        borrowBalance[asset] += amount;
    }

    function repay(address asset, uint256 amount) external onlyOwner {
        require(borrowBalance[asset] >= amount, "Repay amount exceeds borrow balance");
        borrowBalance[asset] -= amount;
    }

    function supply(address asset, uint256 amount) external onlyOwner{
        supplyBalance[asset] += amount;
    }

    function withdraw(address asset, uint256 amount) external onlyOwner{
        require(supplyBalance[asset] >= amount, "Withdraw amount exceeds supply balance");
        supplyBalance[asset] -= amount;
    }
}