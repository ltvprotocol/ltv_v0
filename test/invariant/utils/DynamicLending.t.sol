// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/dummy/interfaces/IDummyLending.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "./RateMath.sol";

abstract contract DynamicLending is IDummyLending {
    mapping(address => uint256) internal _supplyBalance;
    mapping(address => uint256) internal _borrowBalance;

    mapping(address => uint256) public lastDebtIncreaseBlock;

    uint256 public immutable ratePerBlock;

    constructor(uint256 _ratePerBlock) {
        ratePerBlock = _ratePerBlock;
    }

    function borrowBalance(address asset) public view returns (uint256) {
        uint256 lastBlock = lastDebtIncreaseBlock[asset];
        if (lastBlock == getBlockNumber()) return _borrowBalance[asset];

        uint256 blocksElapsed = getBlockNumber() - lastBlock;

        uint256 debtIncreaseCoeff = RateMath.calculateRatePerBlock(ratePerBlock, blocksElapsed);
        return _borrowBalance[asset] * debtIncreaseCoeff / 10 ** 18;
    }

    function supplyBalance(address asset) external view returns (uint256) {
        return _supplyBalance[asset];
    }

    function borrow(address asset, uint256 amount) external {
        _inceraseDebt(asset);
        _borrowBalance[asset] += amount;
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }
        IERC20(asset).transfer(msg.sender, amount);
    }

    function repay(address asset, uint256 amount) external {
        _inceraseDebt(asset);
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
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }

        IERC20(asset).transfer(msg.sender, amount);
        _supplyBalance[asset] -= amount;
    }

    function _inceraseDebt(address asset) internal {
        _borrowBalance[asset] = borrowBalance(asset);
        lastDebtIncreaseBlock[asset] = getBlockNumber();
    }

    function dealToken(address asset, uint256 amount) internal virtual;

    function getBlockNumber() internal view virtual returns (uint256);
}

contract MockDynamicLending is DynamicLending, Test {
    constructor(uint256 _annualDebtIncreaseRate) DynamicLending(_annualDebtIncreaseRate) {}

    function dealToken(address asset, uint256 amount) internal override {
        deal(asset, address(this), amount);
    }

    function getBlockNumber() internal view override returns (uint256) {
        return block.number;
    }
}
