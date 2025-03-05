// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './interfaces/IDummyLending.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/interfaces/IERC20.sol';

contract DummyLending is IDummyLending, Ownable {
    mapping(address => uint256) public supplyBalance;
    mapping(address => uint256) public borrowBalance;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function borrow(address asset, uint256 amount) external onlyOwner {
        borrowBalance[asset] += amount;
        IERC20(asset).transfer(msg.sender, amount);
    }

    function repay(address asset, uint256 amount) external onlyOwner {
        require(borrowBalance[asset] >= amount, "Repay amount exceeds borrow balance");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        borrowBalance[asset] -= amount;
    }

    function supply(address asset, uint256 amount) external onlyOwner{
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        supplyBalance[asset] += amount;
    }

    function withdraw(address asset, uint256 amount) external onlyOwner{
        require(supplyBalance[asset] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(asset).transfer(msg.sender, amount);
        supplyBalance[asset] -= amount;
    }
}