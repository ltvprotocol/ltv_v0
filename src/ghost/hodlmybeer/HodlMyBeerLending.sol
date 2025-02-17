// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import 'forge-std/interfaces/IERC20.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../spooky/ISpookyOracle.sol";

contract HodlMyBeerLending is Initializable {
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

        if((supplyBalance[msg.sender] * collateralPrice) * 95 < (borrowPrice * (borrowBalance[msg.sender] + amount)) * 100) {
            require(false, "Collateral ratio is too low");
        }

        // TODO: add reentrancy guard

        borrowBalance[msg.sender] += amount;
        IERC20(borrowToken).transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {

        // TODO: add reentrancy guard

        require(borrowBalance[msg.sender] >= amount, "Repay amount exceeds borrow balance");
        IERC20(borrowToken).transferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
    }

    function supply(uint256 amount) external {

        // TODO: add reentrancy guard

        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        supplyBalance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {

        uint256 borrowPrice = ISpookyOracle(oracle).getAssetPrice(borrowToken);
        uint256 collateralPrice = ISpookyOracle(oracle).getAssetPrice(collateralToken);

        if(((supplyBalance[msg.sender] - amount) * collateralPrice) * 95 < (borrowPrice * borrowBalance[msg.sender]) * 100) {
            require(false, "Collateral ratio is too low");
        }

        // TODO: check possible liquidation

        require(supplyBalance[msg.sender] >= amount, "Withdraw amount exceeds supply balance");
        IERC20(collateralToken).transfer(msg.sender, amount);
        supplyBalance[msg.sender] -= amount;
    }
}