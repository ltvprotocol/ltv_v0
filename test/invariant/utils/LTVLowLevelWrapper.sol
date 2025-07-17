// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BasicInvariantWrapper} from "./BasicInvariantWrapper.t.sol";

/**
 * @title LTVLowLevelWrapper
 * @dev Wrapper contract for testing LTV low-level rebalance operations
 * 
 * This contract extends BasicInvariantWrapper to provide fuzzable functions for
 * low-level rebalance operations with invariant post checks.
 */
contract LTVLowLevelWrapper is BasicInvariantWrapper {
    /**
     * @dev Constructor initializes the low-level wrapper
     * @param _ltv The LTV protocol contract
     * @param _actors Array of test actors
     */
    constructor(ILTV _ltv, address[10] memory _actors) BasicInvariantWrapper(_ltv, _actors) {}

    /**
     * @dev Calculates the minimum collateral amount user can provide
     * @return Minimum collateral amount (can be negative)
     */
    function minLowLevelRebalanceCollateral() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(currentActor));
        (int256 collateral,) = ltv.previewLowLevelRebalanceShares(-userBalance);
        return collateral;
    }

    /**
     * @dev Calculates the minimum borrow amount user can provide
     * @return Minimum borrow amount (can be negative)
     */
    function minLowLevelRebalanceBorrow() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(currentActor));
        (, int256 borrow) = ltv.previewLowLevelRebalanceShares(-userBalance);
        return borrow;
    }

    /**
     * @dev Wrapper above executeLowLevelRebalanceBorrow function to prepare it's execution and ensure
     * post checks. Mint tokens for user if needed.
     * @param amount Amount of borrow tokens user wants to give or receive(negative = give, positive = receive)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function executeLowLevelRebalanceBorrow(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get valid range for borrow adjustment
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = minLowLevelRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        // Bound the amount to valid range
        amount = bound(amount, minBorrow, maxBorrow);

        // Preview the operation to get expected changes
        (deltaCollateral, deltaLtv) = ltv.previewLowLevelRebalanceBorrow(amount);
        deltaBorrow = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), currentActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        // Capture state before operation
        getInvariantsData();

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
    function executeLowLevelRebalanceBorrowHint(int256 amount, bool hint, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get valid range for borrow adjustment
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = minLowLevelRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        // Bound the amount to valid range
        amount = bound(amount, minBorrow, maxBorrow);

        // Preview the operation with hint to get expected changes
        (deltaCollateral, deltaLtv) = ltv.previewLowLevelRebalanceBorrowHint(amount, hint);
        deltaBorrow = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), currentActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        // Capture state before operation
        getInvariantsData();

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
    function executeLowLevelRebalanceCollateral(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get valid range for collateral adjustment
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = minLowLevelRebalanceCollateral();

        vm.assume(maxCollateral >= minCollateral);

        // Bound the amount to valid range
        amount = bound(amount, minCollateral, maxCollateral);

        // Preview the operation to get expected changes
        (deltaBorrow, deltaLtv) = ltv.previewLowLevelRebalanceCollateral(amount);
        deltaCollateral = amount;

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }
        
        // Capture state before operation
        getInvariantsData();

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
    function executeLowLevelRebalanceCollateralHint(
        int256 amount,
        bool hint,
        uint256 actorIndexSeed,
        uint256 blocksDelta
    ) external useActor(actorIndexSeed) makePostCheck {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get valid range for collateral adjustment
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = minLowLevelRebalanceCollateral();

        vm.assume(maxCollateral >= minCollateral);

        // Bound the amount to valid range
        amount = bound(amount, minCollateral, maxCollateral);

        // Preview the operation with hint to get expected changes
        (deltaBorrow, deltaLtv) = ltv.previewLowLevelRebalanceCollateralHint(amount, hint);
        deltaCollateral = amount;

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(amount)) {
                deal(ltv.collateralToken(), currentActor, uint256(amount));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(amount)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(amount));
            }
        }
        
        // Capture state before operation
        getInvariantsData();

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
    function executeLowLevelRebalanceShares(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get valid range for shares adjustment
        int256 maxShares = ltv.maxLowLevelRebalanceShares();
        int256 minShares = -int256(ltv.balanceOf(currentActor));

        vm.assume(maxShares >= minShares);

        // Bound the amount to valid range
        amount = bound(amount, minShares, maxShares);

        // Preview the operation to get expected changes
        (deltaCollateral, deltaBorrow) = ltv.previewLowLevelRebalanceShares(amount);
        deltaLtv = amount;

        // Handle collateral requirements (if positive, user needs to provide collateral)
        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        // Handle borrow requirements (if negative, user needs to provide borrow tokens)
        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }
        
        // Capture state before operation
        getInvariantsData();

        // Execute the rebalance operation
        ltv.executeLowLevelRebalanceShares(amount);
    }
}
