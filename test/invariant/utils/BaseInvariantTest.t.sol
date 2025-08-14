// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit, DummyLendingConnector, DummyOracleConnector} from "../../utils/BaseTest.t.sol";
import "./BaseInvariantWrapper.t.sol";
import "./DynamicLending.t.sol";
import "./DynamicOracle.t.sol";

/**
 * @title BaseInvariantTest
 * @dev Base contract for invariant testing of the LTV protocol
 *
 * This contract provides the foundational setup for invariant testing by:
 * - Initializing the LTV protocol with test parameters
 * - Setting up dynamic oracle and lending protocol mocks
 * - Configuring actor management and invariant tests
 * - Providing common invariant checking logic
 *
 * Child contracts should inherit from this and implement specific test scenarios
 */
abstract contract BaseInvariantTest is BaseTest {
    uint256 private constant YEARLY_DEBT_INCREASE_RATE = 1000000128033583744; // 40% yearly debt increase
    uint256 private constant YEARLY_PRICE_INCREASE_RATE = 1000000178844623744; // 60% yearly price increase

    /**
     * @dev Sets up the test environment for invariant testing
     *
     * This function:
     * 1. Initializes the LTV protocol with realistic test parameters
     * 2. Creates the invariant wrapper contract
     * 3. Configures invariant tests to exclude invariant checking functions and include wrapper
     * 4. Deploys and configures dynamic oracle and lending protocol mocks
     */
    function setUp() public virtual {
        // Initialize LTV protocol with test parameters
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(100),
            futureBorrow: 0,
            futureCollateral: 0,
            auctionReward: 0,
            startAuction: 0,
            collateralSlippage: 10 ** 16, // 1% slippage tolerance
            borrowSlippage: 10 ** 16, // 1% slippage tolerance
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 2 * 10 ** 19, // 20 collateral tokens
            borrowAssets: 35 * 10 ** 18, // 35 borrow tokens
            maxSafeLTVDividend: 9, // 90% max safe LTV
            maxSafeLTVDivider: 10, // 90% max safe LTV
            minProfitLTVDividend: 5, // 50% min profit LTV
            minProfitLTVDivider: 10, // 50% min profit LTV
            targetLTVDividend: 75, // 75% target LTV
            targetLTVDivider: 100, // 75% target LTV
            maxGrowthFeeDividend: 1, // 20% max growth fee
            maxGrowthFeeDivider: 5,
            collateralPrice: 2 * 10 ** 18, // 2 collateral price
            borrowPrice: 10 ** 18, // 1 borrow price
            maxDeleverageFeeDividend: 0, // No deleverage fee
            maxDeleverageFeeDivider: 1,
            zeroAddressTokens: 4 * 10 ** 19 - 35 * 10 ** 18 // adjust initial share price to be 1
        });

        // Initialize the test environment
        initializeTest(init);

        // Start from block 0 for consistent testing
        vm.roll(0);

        // Create the invariant wrapper contract
        createWrapper();

        // Set the wrapper as the target for fuzzing
        targetContract(wrapper());

        // Exclude invariant checking functions from fuzzing
        // This prevents the fuzzer from calling verifyAndResetInvariants() directly
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("verifyAndResetInvariants()"));
        excludeSelector(FuzzSelector({addr: wrapper(), selectors: selectors}));

        // Deploy dynamic lending protocol with 40% yearly debt increase
        DynamicLending _lending = new MockDynamicLending(YEARLY_DEBT_INCREASE_RATE);

        DynamicOracle _oracle = new DynamicOracle(
            address(ltv.collateralToken()),
            address(ltv.borrowToken()),
            init.collateralPrice,
            init.borrowPrice,
            YEARLY_PRICE_INCREASE_RATE
        );

        // Replace the existing oracle and lending protocol with our dynamic mocks
        // This allows us to simulate realistic market conditions during testing
        vm.etch(address(oracle), address(_oracle).code);
        vm.etch(address(lendingProtocol), address(_lending).code);
    }

    /**
     * @dev Hook called after each invariant test run
     *
     * This function verifies that the max growth fee was properly applied
     * during the test execution, ensuring the protocol's fee mechanism works correctly.
     *
     * Note: This post check needed to make sure that max growth fee check
     * was executed at least once, which ensures it's validity. Important to say that
     * there are some cases where max growth fee can be not applied which can lead to
     * invariant test failure. However, this probability is very low and can be ignored.
     * It's considered that if invariant test fails here, then something's wrong.
     */
    function afterInvariant() public view virtual {
        assertTrue(BaseInvariantWrapper(wrapper()).maxGrowthFeeReceived());
    }

    /**
     * @dev Abstract function to return the wrapper contract address
     * @return Address of the invariant wrapper contract
     */
    function wrapper() internal view virtual returns (address);

    /**
     * @dev Abstract function to create the invariant wrapper contract
     * Child contracts must implement this to create their specific wrapper
     */
    function createWrapper() internal virtual;

    /**
     * @dev Creates an array of 10 test actors (addresses 1-10)
     * These actors are used by the fuzzer to simulate different users
     * interacting with the protocol
     * @return Array of 10 actor addresses
     */
    function actors() internal virtual returns (address[10] memory) {
        address[10] memory _testActors;
        for (uint256 i = 0; i < 10; i++) {
            _testActors[i] = address(uint160(i + 1));
        }
        return _testActors;
    }
}
