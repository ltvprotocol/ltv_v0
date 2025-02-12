// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import 'forge-std/interfaces/IERC20.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HodlMyBeerLending is Initializable {
    mapping(address => uint256) public supplyBalance;
    mapping(address => uint256) public borrowBalance;

    address public borrowToken;
    address public collateralToken;
    // TODO: add space for upgradability

    // TODO: add events

    function initialize(address _borrowToken, address _collateralToken) public initializer {
        borrowToken = _borrowToken;
        collateralToken = _collateralToken;
    }

    function borrow(uint256 amount) external {

        // TODO: check collateral ratio with some specific LTV
        // TODO: add reentrancy guard

        borrowBalance[msg.sender] += amount;
        IERC20(borrowToken).transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {

        // TODO: add reentrancy guard

        require(borrowBalance[msg.sender] >= amount, "Repay amount exceeds borrow balance");
        IERC20(borrowToken).transferFrom(msg.sender, address(this), amount);
        borrowBalance[borrowToken] -= amount;
    }

    function supply(address asset, uint256 amount) external {

        // TODO: add reentrancy guard

        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        supplyBalance[asset] += amount;
    }

    function withdraw(address asset, uint256 amount) external {

        // TODO: add reentrancy guard
        // TODO: check possible liquidation

        require(supplyBalance[msg.sender] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(collateralToken).transfer(msg.sender, amount);
        supplyBalance[asset] -= amount;
    }
}