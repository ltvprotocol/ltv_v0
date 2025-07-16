// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/dummy/interfaces/IDummyLending.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";

abstract contract DynamicLending is IDummyLending {
    mapping(address => uint256) internal _supplyBalance;
    mapping(address => uint256) internal _borrowBalance;

    mapping(address => uint256) public lastDebtIncreaseBlock;

    uint256 public immutable annualDebtIncreaseRate;
    uint256 public constant DEBT_INCREASE_PRECISION = 10 ** 18;
    uint256 public constant BLOCKS_PER_YEAR = 2628000;

    constructor(uint256 _annualDebtIncreaseRate) {
        annualDebtIncreaseRate = _annualDebtIncreaseRate;
    }

    function borrowBalance(address asset) external view returns (uint256) {
        return _borrowBalance[asset] + getDebtIncreaseRate(asset);
    }

    function supplyBalance(address asset) external view returns (uint256) {
        return _supplyBalance[asset];
    }

    function borrow(address asset, uint256 amount) external {
        _borrowBalance[asset] += amount;
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }
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
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }

        IERC20(asset).transfer(msg.sender, amount);
        _supplyBalance[asset] -= amount;
    }

    function getDebtIncreaseRate(address asset) public view returns (uint256) {
        uint256 lastBlock = lastDebtIncreaseBlock[asset];
        if (lastBlock == 0) return 0;

        uint256 blocksElapsed = getBlockNumber() - lastBlock;

        uint256 debtIncrease = (_borrowBalance[asset] * annualDebtIncreaseRate * blocksElapsed)
            / (DEBT_INCREASE_PRECISION * BLOCKS_PER_YEAR);
        return debtIncrease;
    }

    function _inceraseDebt(address asset) internal {
        uint256 debtIncrease = getDebtIncreaseRate(asset);
        _borrowBalance[asset] += debtIncrease;
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