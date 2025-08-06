// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/dummy/interfaces/IDummyLending.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "./RateMath.sol";

/**
 * @title DynamicLending
 * @dev Abstract mock lending protocol for invariant testing
 *
 * This contract simulates a lending protocol where:
 * - Users can supply and borrow assets
 * - Borrowed amounts accumulate interest over time
 * - Interest rates are configurable and compound per block
 * - Balances are tracked separately for supply and borrow positions
 */
abstract contract DynamicLending is IDummyLending {
    // Mapping from asset address to user's supplied balance
    mapping(address => uint256) internal _supplyBalance;

    // Mapping from asset address to user's borrowed balance (before interest)
    mapping(address => uint256) internal _borrowBalance;

    // Mapping from asset address to the last block where debt was increased
    // Used to calculate interest accrual
    mapping(address => uint256) public lastDebtIncreaseBlock;

    // Rate per block for debt increase (interest rate) in 1e18 precision
    uint256 public immutable ratePerBlock;

    /**
     * @dev Constructor sets the interest rate for debt accumulation
     * @param _ratePerBlock Interest rate per block in 1e18 precision
     */
    constructor(uint256 _ratePerBlock) {
        ratePerBlock = _ratePerBlock;
    }

    /**
     * @dev Returns the current borrow balance including accrued interest
     * @param asset Address of the borrowed asset
     * @return Current borrow balance with interest
     */
    function borrowBalance(address asset) public view returns (uint256) {
        uint256 lastBlock = lastDebtIncreaseBlock[asset];

        // If debt was already increased this block, return current balance
        if (lastBlock == uint56(block.number)) return _borrowBalance[asset];

        // Calculate blocks elapsed since last debt increase
        uint256 blocksElapsed = uint56(block.number) - lastBlock;

        // Calculate the cumulative interest factor using RateMath
        uint256 debtIncreaseCoeff = RateMath.calculateRatePerBlock(ratePerBlock, blocksElapsed);

        // Apply interest to the base borrow balance
        return _borrowBalance[asset] * debtIncreaseCoeff / 10 ** 18;
    }

    /**
     * @dev Returns the user's supplied balance for an asset
     * @param asset Address of the supplied asset
     * @return Current supply balance
     */
    function supplyBalance(address asset) external view returns (uint256) {
        return _supplyBalance[asset];
    }

    /**
     * @dev Allows a user to borrow an asset
     * @param asset Address of the asset to borrow
     * @param amount Amount to borrow
     */
    function borrow(address asset, uint256 amount) external {
        // Update debt to include accrued interest before adding new borrow
        _inceraseDebt(asset);

        // Add the new borrow amount to the base balance
        _borrowBalance[asset] += amount;

        // Ensure the protocol has enough tokens to lend
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }

        // Transfer tokens to the borrower
        IERC20(asset).transfer(msg.sender, amount);
    }

    /**
     * @dev Allows a user to repay borrowed assets
     * @param asset Address of the asset to repay
     * @param amount Amount to repay
     */
    function repay(address asset, uint256 amount) external {
        // Update debt to include accrued interest before repayment
        _inceraseDebt(asset);

        // Ensure user isn't repaying more than they owe
        require(_borrowBalance[asset] >= amount, "Repay amount exceeds borrow balance");

        // Transfer tokens from user to protocol
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Reduce the borrow balance
        _borrowBalance[asset] -= amount;
    }

    /**
     * @dev Allows a user to supply assets to the protocol
     * @param asset Address of the asset to supply
     * @param amount Amount to supply
     */
    function supply(address asset, uint256 amount) external {
        // Transfer tokens from user to protocol
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Increase the user's supply balance
        _supplyBalance[asset] += amount;
    }

    /**
     * @dev Allows a user to withdraw supplied assets
     * @param asset Address of the asset to withdraw
     * @param amount Amount to withdraw
     */
    function withdraw(address asset, uint256 amount) external {
        // Ensure user isn't withdrawing more than they supplied
        require(_supplyBalance[asset] >= amount, "Withdraw amount exceeds supply balance");

        // Ensure protocol has enough tokens to return
        if (IERC20(asset).balanceOf(address(this)) < amount) {
            dealToken(asset, amount);
        }

        // Transfer tokens from protocol to user
        IERC20(asset).transfer(msg.sender, amount);

        // Reduce the user's supply balance
        _supplyBalance[asset] -= amount;
    }

    /**
     * @dev Internal function to update debt with accrued interest
     * This is called before any borrow/repay operations to ensure
     * interest is properly calculated and applied
     * @param asset Address of the asset whose debt should be updated
     */
    function _inceraseDebt(address asset) internal {
        // Update borrow balance
        _borrowBalance[asset] = borrowBalance(asset);

        // Update the last debt increase block to current block
        lastDebtIncreaseBlock[asset] = uint56(block.number);
    }

    /**
     * @dev Abstract function to mint tokens for the protocol
     * Implemented by concrete classes to provide tokens when needed
     * @param asset Address of the asset to mint
     * @param amount Amount to mint
     */
    function dealToken(address asset, uint256 amount) internal virtual;
}

/**
 * @title MockDynamicLending
 * @dev Concrete implementation of DynamicLending for testing
 *
 * This implementation uses Foundry's testing utilities to mint tokens when the protocol needs them (deal function)
 */
contract MockDynamicLending is DynamicLending, Test {
    /**
     * @dev Constructor takes annual debt increase rate and converts to per-block rate
     * @param _annualDebtIncreaseRate Annual interest rate in 1e18 precision
     */
    constructor(uint256 _annualDebtIncreaseRate) DynamicLending(_annualDebtIncreaseRate) {}

    /**
     * @dev Implementation of dealToken using Foundry's deal function
     * @param asset Address of the asset to mint
     * @param amount Amount to mint
     */
    function dealToken(address asset, uint256 amount) internal override {
        deal(asset, address(this), amount);
    }
}
