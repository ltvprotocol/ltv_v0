// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "../../../src/Constants.sol";
import "../../../src/dummy/DummyOracleConnector.sol";

/**
 * @title BasicInvariantWrapper
 * @dev Core contract for invariant testing of the LTV protocol
 * 
 * This contract wraps the LTV protocol and provides invariant checking functionality.
 * It tracks state changes before and after operations to ensure the protocol maintains
 * its fundamental properties (invariants) throughout all operations.
 * 
 * Key invariants checked:
 * - Token price never decreases (totalAssets * totalSupply relationship)
 * - User balances change correctly (no tokens lost or gained unexpectedly)
 * - Fee collection works properly (max growth fee, auction rewards)
 * - Protocol state remains consistent
 */
contract BasicInvariantWrapper is Test {
    // Reference to the LTV protocol being tested
    ILTV internal ltv;
    
    // Array of 10 test actors used by the fuzzer
    address[10] public actors;
    
    // Current actor performing the operation
    address internal currentActor;

    // Protocol state variables tracked before operations
    uint256 internal totalAssets;      // Total assets in the protocol
    uint256 internal totalSupply;      // Total LTV token supply

    // User balance tracking variables (before operation)
    int256 internal borrowUserBalanceBefore;      // User's borrow token balance
    int256 internal collateralUserBalanceBefore;  // User's collateral token balance
    int256 internal ltvUserBalanceBefore;         // User's LTV token balance
    
    // Expected changes in user balances (delta = after - before)
    int256 internal deltaBorrow;       // Expected change in borrow balance
    int256 internal deltaCollateral;   // Expected change in collateral balance
    int256 internal deltaLtv;          // Expected change in LTV balance
    
    // Price tracking for fee detection
    uint256 internal lastSeenTokenPriceBefore;  // Token price before operation

    // Fee collector balance tracking (before operation)
    uint256 internal feeCollectorBorrowBalanceBefore;
    uint256 internal feeCollectorCollateralBalanceBefore;
    uint256 internal feeCollectorLtvBalanceBefore;

    // Protocol state tracking (before operation)
    int256 internal futureCollateralBefore;  // Future collateral assets
    int256 internal rewardsBefore;           // Calculated rewards value
    uint256 internal startAuction;           // Auction start block

    // Block progression tracking
    uint256 internal blockDelta;  // Number of blocks advanced

    // Flag to ensure data is initialized before checking invariants
    bool internal dataInitialized;

    // Flags to track if specific events occurred during testing
    bool public maxGrowthFeeReceived;    // True if max growth fee was applied
    bool public auctionRewardsReceived;  // True if auction rewards were distributed

    /**
     * @dev Constructor initializes the wrapper with LTV protocol and actors
     * @param _ltv The LTV protocol contract to test
     * @param _actors Array of 10 test actor addresses
     */
    constructor(ILTV _ltv, address[10] memory _actors) {
        vm.startPrank(address(1));
        ltv = _ltv;
        actors = _actors;
        vm.stopPrank();
    }

    /**
     * @dev Modifier that sets up a random actor for the operation
     * @param actorIndexSeed Fuzzer seed to select actor
     */
    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    /**
     * @dev Modifier that ensures invariants are checked after the operation
     */
    modifier makePostCheck() {
        _;
        checkAndResetInvariants();
    }

    /**
     * @dev Captures the current state before an operation
     * 
     * This function records all relevant balances and state variables
     * that will be used to verify invariants after the operation completes.
     * It must be called before any operation that changes protocol state.
     */
    function getInvariantsData() internal virtual {
        // Capture protocol total assets
        totalAssets = ltv.totalAssets();
        // Get real total supply (can be affected by max growth fee)
        totalSupply = ltv.convertToShares(totalAssets);
        
        // Capture user balances
        borrowUserBalanceBefore = int256(IERC20(ltv.borrowToken()).balanceOf(currentActor));
        ltvUserBalanceBefore = int256(ltv.balanceOf(currentActor));
        collateralUserBalanceBefore = int256(IERC20(ltv.collateralToken()).balanceOf(currentActor));
        
        // Capture fee collector balances
        feeCollectorBorrowBalanceBefore = IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector());
        feeCollectorCollateralBalanceBefore = IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector());
        feeCollectorLtvBalanceBefore = ltv.balanceOf(ltv.feeCollector());
        
        // Capture protocol auction state
        futureCollateralBefore = ltv.futureCollateralAssets();
        
        // Calculate current rewards value in underlying asset terms
        int256 borrowPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceBorrowOracle());
        int256 collateralPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceCollateralOracle());
        rewardsBefore = (
            ltv.futureRewardBorrowAssets() * borrowPrice - ltv.futureRewardCollateralAssets() * collateralPrice
        ) / int256(Constants.ORACLE_DIVIDER);
        
        startAuction = ltv.startAuction();

        dataInitialized = true;
    }

    /**
     * @dev Core invariant checking function
     * 
     * This function verifies that the protocol maintains its fundamental properties
     * after each operation. It checks multiple invariants:
     * 
     * 1. Token price never decreases (totalAssets * totalSupply relationship)
     * 2. User balances change exactly as expected (no unexpected token movements)
     * 3. Fee collection works properly (max growth fee, auction rewards)
     * 4. Protocol state remains consistent
     */
    function checkAndResetInvariants() public virtual {
        if (!dataInitialized) {
            return;
        }

        // Invariant 1: Token price never decreases
        // This ensures the protocol doesn't lose value for existing holders
        assertGe(ltv.totalAssets() * totalSupply, totalAssets * ltv.totalSupply(), "Token price became smaller");
        
        // Invariant 2: User balances change exactly as expected
        assertEq(
            int256(IERC20(ltv.borrowToken()).balanceOf(currentActor)),
            borrowUserBalanceBefore + deltaBorrow,
            "Borrow balance changed"
        );
        assertEq(
            int256(IERC20(ltv.collateralToken()).balanceOf(currentActor)),
            collateralUserBalanceBefore - deltaCollateral,
            "Collateral balance changed"
        );
        assertEq(int256(ltv.balanceOf(currentActor)), ltvUserBalanceBefore + deltaLtv, "LTV balance changed");

        // Invariant 3: Check for auction rewards distribution
        // Calculate current rewards value
        int256 borrowPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceBorrowOracle());
        int256 collateralPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceCollateralOracle());
        int256 rewardsAfter = (
            ltv.futureRewardBorrowAssets() * borrowPrice - ltv.futureRewardCollateralAssets() * collateralPrice
        ) / int256(Constants.ORACLE_DIVIDER);
        
        // Check if auction was executed and rewards should be distributed
        // Multiply by 10 to account for rounding errors
        if (
            startAuction + Constants.AMOUNT_OF_STEPS > block.number && checkAuctionExecuted()
                && rewardsBefore - rewardsAfter >= 10 * int256(Constants.AMOUNT_OF_STEPS)
        ) {
            // Verify that fee collector received rewards
            assertTrue(
                feeCollectorBorrowBalanceBefore < IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector())
                    || feeCollectorCollateralBalanceBefore < IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector())
                    || feeCollectorLtvBalanceBefore < ltv.balanceOf(ltv.feeCollector()),
                "Auction rewards received"
            );
            auctionRewardsReceived = true;
        }

        // Invariant 4: Check for max growth fee application
        // This fee is applied when token price increases and user performs operations
        if (
            lastSeenTokenPriceBefore != ltv.lastSeenTokenPrice()
                && (deltaBorrow * deltaCollateral != 0 || deltaBorrow * deltaLtv != 0 || deltaCollateral * deltaLtv != 0)
        ) {
            assertLt(feeCollectorLtvBalanceBefore, ltv.balanceOf(ltv.feeCollector()), "Max growth fee applied");
            maxGrowthFeeReceived = true;
        }

        // Reset all tracking variables for next operation
        blockDelta = 0;
        totalAssets = 0;
        totalSupply = 0;
        borrowUserBalanceBefore = 0;
        collateralUserBalanceBefore = 0;
        ltvUserBalanceBefore = 0;
        deltaBorrow = 0;
        deltaCollateral = 0;
        lastSeenTokenPriceBefore = 0;
        feeCollectorBorrowBalanceBefore = 0;
        feeCollectorCollateralBalanceBefore = 0;
        feeCollectorLtvBalanceBefore = 0;
        futureCollateralBefore = 0;
        dataInitialized = false;
    }

    /**
     * @dev Checks if an auction was executed by comparing future collateral assets
     * @return True if auction was executed (future collateral changed)
     */
    function checkAuctionExecuted() internal view returns (bool) {
        return (
            futureCollateralBefore > 0 && futureCollateralBefore > ltv.futureCollateralAssets()
                || futureCollateralBefore < 0 && futureCollateralBefore < ltv.futureCollateralAssets()
        );
    }

    /**
     * @dev Advances the blockchain by a specified number of blocks
     * @param blocks Number of blocks to advance (bounded between 1 and AMOUNT_OF_STEPS)
     */
    function moveBlock(uint256 blocks) internal {
        lastSeenTokenPriceBefore = ltv.lastSeenTokenPrice();
        blockDelta = bound(blocks, 1, Constants.AMOUNT_OF_STEPS);
        vm.roll(block.number + blockDelta);
    }
}
