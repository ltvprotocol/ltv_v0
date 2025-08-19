// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseInvariantTest} from "test/invariant/utils/BaseInvariantTest.t.sol";
import {VaultInvariantWrapper, ILTV} from "test/invariant/utils/VaultInvariantWrapper.t.sol";

/**
 * @title VaultInvariantTest
 * @dev Invariant test contract specifically for LTV vault operations
 *
 * This contract tests the LTV protocol's vault functionality using invariant testing.
 * Vault operations include standard DeFi vault functions like deposit, withdraw,
 * mint, and redeem for both borrow tokens and collateral tokens.
 *
 * The test ensures that:
 * - All vault operations maintain protocol invariants
 * - User balances are correctly updated after operations
 * - Token transfers work properly in all scenarios
 * - Fee collection mechanisms function correctly
 * - Auction rewards are distributed appropriately
 * - The protocol remains in a consistent state after all operations
 */
contract VaultInvariantTest is BaseInvariantTest {
    // Instance of the vault wrapper
    VaultInvariantWrapper internal _wrapper;

    /**
     * @dev Returns the address of the wrapper contract for fuzzing
     * @return Address of the LTVVaultWrapper contract
     */
    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    /**
     * @dev Creates the vault wrapper contract
     * This wrapper provides fuzzable functions for all vault operations
     */
    function createWrapper() internal override {
        _wrapper = new VaultInvariantWrapper(ILTV(address(ltv)), actors());
    }

    /**
     * @dev Sets up the test environment for vault operation testing
     *
     * This function:
     * 1. Calls the parent setUp to initialize the basic test environment
     * 2. Performs an initial mint operation to establish a baseline state
     *    with some LTV tokens in circulation
     */
    function setUp() public virtual override {
        // Initialize the basic test environment
        super.setUp();

        // Perform an initial mint operation to establish a baseline state
        // This ensures vault will be in target LTV state after auction exection
        _wrapper.fuzzMint(1, 0, 100);
    }

    /**
     * @dev Hook called after each invariant test run
     *
     * This function verifies that:
     * 1. The max growth fee was properly applied (from parent)
     * 2. Auction rewards were received during testing
     *
     * These checks ensure that the protocol's fee and reward mechanisms
     * are working correctly throughout the invariant testing process.
     *
     * Note: This post check needed to make sure that auction reward check
     * was executed at least once, which ensures it's validity. Important to say that
     * there are some cases where auction rewards can be not applied which can lead to
     * invariant test failure. However, this probability is very low and can be ignored.
     * It's considered that if invariant test fails here, then something's wrong.
     */
    function afterInvariant() public view override {
        // Call parent to check max growth fee
        super.afterInvariant();

        // Verify that auction rewards were received during testing
        // This ensures the auction mechanism is functioning properly
        assertTrue(_wrapper.auctionRewardsReceived());
    }

    /**
     * @dev The main invariant test function
     *
     * This function is called by the fuzzer to test vault operations.
     * The actual testing logic is handled by the wrapper contract, which:
     * - Randomly selects actors and operations
     * - Performs various vault operations (deposit, withdraw, mint, redeem)
     * - Verifies that all invariants are maintained
     * - Ensures proper token transfers and balance updates
     *
     * The fuzzer will call various functions on the wrapper contract to test
     * different scenarios and ensure the vault remains robust and secure.
     */
    function invariant_vault() public pure {}
}
