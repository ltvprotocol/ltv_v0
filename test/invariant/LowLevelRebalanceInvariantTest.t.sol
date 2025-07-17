// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseInvariantTest} from "./utils/BaseInvariantTest.t.sol";
import {LowLevelRebalanceInvariantWrapper, ILTV} from "./utils/LowLevelRebalanceInvariantWrapper.t.sol";

/**
 * @title LowLevelRebalanceInvariantTest
 * @dev Invariant test contract specifically for low-level rebalance operations
 * 
 * This contract tests the LTV protocol's low-level rebalance functionality using
 * invariant testing.
 * 
 * The test ensures that:
 * - All low-level rebalance operations maintain protocol invariants
 * - The protocol remains in a consistent state after rebalance operations
 * - No tokens are lost or gained unexpectedly during rebalancing
 */
contract LowLevelRebalanceInvariantTest is BaseInvariantTest {
    // Instance of the low-level rebalance wrapper
    LowLevelRebalanceInvariantWrapper internal _lowLevelWrapper;

    /**
     * @dev Returns the address of the wrapper contract for fuzzing
     * @return Address of the LTVLowLevelWrapper contract
     */
    function wrapper() internal view override returns (address) {
        return address(_lowLevelWrapper);
    }

    /**
     * @dev Creates the low-level rebalance wrapper contract
     * This wrapper provides fuzzable functions for all low-level rebalance operations
     */
    function createWrapper() internal override {
        _lowLevelWrapper = new LowLevelRebalanceInvariantWrapper(ILTV(address(ltv)), actors());
    }

    /**
     * @dev Sets up the test environment for low-level rebalance testing
     * 
     * This function:
     * 1. Calls the parent setUp to initialize the basic test environment
     * 2. Performs an initial rebalance operation to establish a baseline state
     */
    function setUp() public override {
        // Initialize the basic test environment
        super.setUp();
        
        // Set less maximum total assets to avoid overflows
        vm.startPrank(ltv.governor());
        ltv.setMaxTotalAssetsInUnderlying(type(uint120).max);
        vm.stopPrank();
        
        // Perform an initial rebalance operation with zero amount
        // This establishes a baseline state and ensures the protocol is properly initialized
        _lowLevelWrapper.fuzzLowLevelRebalanceShares(0, 0, 100);
    }

    /**
     * @dev The main invariant test function
     * 
     * This function is called by the fuzzer to test low-level rebalance operations.
     * The actual testing logic is handled by the wrapper contract, which:
     * - Randomly selects actors and operations
     * - Performs low-level rebalance operations
     * - Verifies that all invariants are maintained
     * 
     * The fuzzer will call various functions on the wrapper contract to test
     * different scenarios and ensure the protocol remains robust.
     */
    function invariant_lowLevelRebalance() public pure {}
}
