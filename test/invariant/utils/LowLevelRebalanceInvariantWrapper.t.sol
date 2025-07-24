// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BaseInvariantWrapper} from "./BaseInvariantWrapper.t.sol";

/**
 * @title LTVLowLevelWrapper
 * @dev Wrapper contract for testing LTV low-level rebalance operations
 *
 * This contract extends BaseInvariantWrapper to provide fuzzable functions for
 * low-level rebalance operations with invariant post checks.
 */
abstract contract BaseLowLevelRebalanceInvariantWrapper is BaseInvariantWrapper {
    /**
     * @dev Calculates the minimum collateral amount user can provide
     * @return Minimum collateral amount (can be negative)
     */
    function getMinRebalanceCollateral() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(_currentTestActor));
        (int256 collateral,) = ltv.previewLowLevelRebalanceShares(-userBalance);
        // hack to avoid underflows with delta shares
        return collateral + 10;
    }

    /**
     * @dev Calculates the minimum borrow amount user can provide
     * @return Minimum borrow amount (can be negative)
     */
    function getMinRebalanceBorrow() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(_currentTestActor));
        (, int256 borrow) = ltv.previewLowLevelRebalanceShares(-userBalance);
        // hack to avoid underflows with delta shares
        return borrow + 10;
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceBorrow function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of borrow tokens user wants to give or receive(negative = give, positive = receive)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzLowLevelRebalanceBorrow(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get valid range for borrow adjustment
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = getMinRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        // Bound the amount to valid range
        amount = bound(amount, minBorrow, maxBorrow);

        // Preview the operation to get expected changes
        (_expectedCollateralDelta, _expectedLtvDelta) = ltv.previewLowLevelRebalanceBorrow(amount);
        _expectedBorrowDelta = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (_expectedCollateralDelta > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(_expectedCollateralDelta)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(_expectedCollateralDelta));
            }
            if (
                IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv))
                    < uint256(_expectedCollateralDelta)
            ) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(_expectedCollateralDelta));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        // Capture state before operation
        captureInvariantState();

        // Execute the rebalance operation
        ltv.executeLowLevelRebalanceBorrow(amount);
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceBorrowHint function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of borrow tokens user wants to give or receive(negative = give, positive = receive)
     * @param hint Boolean hint for optimization path
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzLowLevelRebalanceBorrowHint(int256 amount, bool hint, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get valid range for borrow adjustment
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = getMinRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        // Bound the amount to valid range
        amount = bound(amount, minBorrow, maxBorrow);

        // Preview the operation with hint to get expected changes
        (_expectedCollateralDelta, _expectedLtvDelta) = ltv.previewLowLevelRebalanceBorrowHint(amount, hint);
        _expectedBorrowDelta = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (_expectedCollateralDelta > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(_expectedCollateralDelta)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(_expectedCollateralDelta));
            }
            if (
                IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv))
                    < uint256(_expectedCollateralDelta)
            ) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(_expectedCollateralDelta));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        // Capture state before operation
        captureInvariantState();

        // Execute the rebalance operation with hint
        ltv.executeLowLevelRebalanceBorrowHint(amount, hint);
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceCollateral function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of collateral tokens user wants to give or receive(negative = receive, positive = give)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzLowLevelRebalanceCollateral(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get valid range for collateral adjustment
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = getMinRebalanceCollateral();

        // Assume that max collateral is greater than min collateral
        vm.assume(maxCollateral >= minCollateral);

        // Bound the amount to valid range
        amount = bound(amount, minCollateral, maxCollateral);

        // Preview the operation to get expected changes
        (_expectedBorrowDelta, _expectedLtvDelta) = ltv.previewLowLevelRebalanceCollateral(amount);
        _expectedCollateralDelta = amount;

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (_expectedBorrowDelta < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(-_expectedBorrowDelta)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(-_expectedBorrowDelta));
            }
            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(-_expectedBorrowDelta)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-_expectedBorrowDelta));
            }
        }

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(_expectedCollateralDelta)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(_expectedCollateralDelta));
            }
            if (
                IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv))
                    < uint256(_expectedCollateralDelta)
            ) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(_expectedCollateralDelta));
            }
        }

        // Capture state before operation
        captureInvariantState();

        // Execute the rebalance operation
        ltv.executeLowLevelRebalanceCollateral(amount);
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceCollateralHint function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of collateral tokens user wants to give or receive(negative = receive, positive = give)
     * @param hint Boolean hint for optimization path
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzLowLevelRebalanceCollateralHint(int256 amount, bool hint, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get valid range for collateral adjustment
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = getMinRebalanceCollateral();

        vm.assume(maxCollateral >= minCollateral);

        // Bound the amount to valid range
        amount = bound(amount, minCollateral, maxCollateral);

        // Preview the operation with hint to get expected changes
        (_expectedBorrowDelta, _expectedLtvDelta) = ltv.previewLowLevelRebalanceCollateralHint(amount, hint);
        _expectedCollateralDelta = amount;

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (_expectedBorrowDelta < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(-_expectedBorrowDelta)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(-_expectedBorrowDelta));
            }
            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(-_expectedBorrowDelta)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-_expectedBorrowDelta));
            }
        }

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(amount)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(amount));
            }
            if (IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv)) < uint256(amount)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(amount));
            }
        }

        // Capture state before operation
        captureInvariantState();

        // Execute the rebalance operation with hint
        ltv.executeLowLevelRebalanceCollateralHint(amount, hint);
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceShares function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of LTV tokens user wants to mint or burn(negative = burm, positive = mint)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzLowLevelRebalanceShares(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get valid range for shares adjustment
        int256 maxShares = ltv.maxLowLevelRebalanceShares();
        int256 minShares = -int256(ltv.balanceOf(_currentTestActor));

        vm.assume(maxShares >= minShares);

        // Bound the amount to valid range
        amount = bound(amount, minShares, maxShares);

        // Preview the operation to get expected changes
        (_expectedCollateralDelta, _expectedBorrowDelta) = ltv.previewLowLevelRebalanceShares(amount);
        _expectedLtvDelta = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (_expectedCollateralDelta > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(_expectedCollateralDelta)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(_expectedCollateralDelta));
            }
            if (
                IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv))
                    < uint256(_expectedCollateralDelta)
            ) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(_expectedCollateralDelta));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (_expectedBorrowDelta < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(-_expectedBorrowDelta)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(-_expectedBorrowDelta));
            }
            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(-_expectedBorrowDelta)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-_expectedBorrowDelta));
            }
        }

        // Capture state before operation
        captureInvariantState();

        // Execute the rebalance operation
        ltv.executeLowLevelRebalanceShares(amount);
    }
}

contract LowLevelRebalanceInvariantWrapper is BaseLowLevelRebalanceInvariantWrapper {
    constructor(ILTV _ltv, address[10] memory _actors) BaseInvariantWrapper(_ltv, _actors) {}
}
