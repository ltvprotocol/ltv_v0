// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ISpookyOracle} from "../spooky/ISpookyOracle.sol";

contract HodlMyBeerLending is Initializable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public supplyCollateralBalance;
    mapping(address => uint256) public supplyBalance;
    mapping(address => uint256) public borrowBalance;

    address public borrowToken;
    address public collateralToken;
    address public oracle;

    // TODO: add events

    function initialize(address _borrowToken, address _collateralToken, address _oracle) public initializer {
        borrowToken = _borrowToken;
        collateralToken = _collateralToken;
        oracle = _oracle;
    }

    function borrow(uint256 amount) external {
        // LTV = 95/100

        uint256 borrowPrice = ISpookyOracle(oracle).getAssetPrice(borrowToken);
        uint256 collateralPrice = ISpookyOracle(oracle).getAssetPrice(collateralToken);

        if (
            (supplyCollateralBalance[msg.sender] * collateralPrice) * 95
                < (borrowPrice * (borrowBalance[msg.sender] + amount)) * 100
        ) {
            require(false, "Collateral ratio is too low");
        }

        // TODO: add reentrancy guard

        borrowBalance[msg.sender] += amount;
        IERC20(borrowToken).safeTransfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        // TODO: add reentrancy guard

        require(borrowBalance[msg.sender] >= amount, "Repay amount exceeds borrow balance");
        IERC20(borrowToken).safeTransferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
    }

    function supplyCollateral(uint256 amount) external {
        // TODO: add reentrancy guard

        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), amount);
        supplyCollateralBalance[msg.sender] += amount;
    }

    function withdrawCollateral(uint256 amount) external {
        // TODO: add reentrancy guard

        uint256 borrowPrice = ISpookyOracle(oracle).getAssetPrice(borrowToken);
        uint256 collateralPrice = ISpookyOracle(oracle).getAssetPrice(collateralToken);

        if (
            ((supplyCollateralBalance[msg.sender] - amount) * collateralPrice) * 95
                < (borrowPrice * borrowBalance[msg.sender]) * 100
        ) {
            require(false, "Collateral ratio is too low");
        }

        require(supplyCollateralBalance[msg.sender] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(collateralToken).safeTransfer(msg.sender, amount);
        supplyCollateralBalance[msg.sender] -= amount;
    }

    function supply(uint256 amount) external {
        // TODO: add reentrancy guard

        IERC20(borrowToken).safeTransferFrom(msg.sender, address(this), amount);
        supplyBalance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        // TODO: add reentrancy guard

        require(supplyBalance[msg.sender] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(borrowToken).safeTransfer(msg.sender, amount);
        supplyBalance[msg.sender] -= amount;
    }
}
