// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {DummyOracleConnector} from "src/dummy/DummyOracleConnector.sol";
import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title BaseInvariantWrapper
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
contract BaseInvariantWrapper is Test {
    using UMulDiv for uint256;

    uint256 private constant PRECISION = 10 ** 18;

    // Reference to the LTV protocol being tested
    ILTV internal ltv;

    // Array of 10 test actors used by the fuzzer
    address[10] public _testActors;

    // Current actor performing the operation
    address internal _currentTestActor;

    // Protocol state variables tracked before operations
    uint256 internal _initialTotalAssets; // Total assets in the protocol
    uint256 internal _initialTotalSupply; // Total LTV token supply

    // User balance tracking variables (before operation)
    int256 internal _initialBorrowBalance; // User's borrow token balance
    int256 internal _initialCollateralBalance; // User's collateral token balance
    int256 internal _initialLtvBalance; // User's LTV token balance

    // Expected changes in user balances (delta = after - before)
    int256 internal _expectedBorrowDelta; // Expected change in borrow balance
    int256 internal _expectedCollateralDelta; // Expected change in collateral balance
    int256 internal _expectedLtvDelta; // Expected change in LTV balance

    // Price tracking for fee detection
    uint256 internal _initialLastSeenTokenPrice; // Highest seen token price before operation

    // Fee collector balance tracking (before operation)
    uint256 internal _initialFeeCollectorBorrowBalance;
    uint256 internal _initialFeeCollectorCollateralBalance;
    uint256 internal _initialFeeCollectorLtvBalance;

    // After auction execution we need to check that sum of collateral and borrow tokens before and after is the same
    bool internal _auctionExecuted;

    // Protocol state tracking (before operation)
    int256 internal _initialFutureCollateral; // Future collateral assets
    int256 internal _initialFutureBorrow; // Future borrow assets
    int256 internal _initialRewardBorrow; // Future reward borrow assets
    int256 internal _initialRewardCollateral; // Future reward collateral assets
    int256 internal _initialRealBorrow; // Real borrow assets
    int256 internal _initialRealCollateral; // Real collateral assets
    uint256 internal _initialAuctionStartBlock; // Auction start block

    // Block progression tracking
    uint256 internal _blocksAdvanced; // Number of blocks advanced

    // Flag to ensure data is initialized before checking invariants
    bool internal _invariantStateCaptured;

    // Flags to track if specific events occurred during testing
    bool public maxGrowthFeeReceived; // True if max growth fee was applied
    bool public auctionRewardsReceived; // True if auction rewards were distributed

    /**
     * @dev Constructor initializes the wrapper with LTV protocol and actors
     * @param _ltv The LTV protocol contract to test
     * @param _actors Array of 10 test actor addresses
     */
    constructor(ILTV _ltv, address[10] memory _actors) {
        vm.startPrank(address(1));
        ltv = _ltv;
        _testActors = _actors;
        vm.stopPrank();
    }

    /**
     * @dev Modifier that sets up a random actor for the operation
     * @param actorIndexSeed Fuzzer seed to select actor
     */
    modifier useActor(uint256 actorIndexSeed) {
        _currentTestActor = _testActors[bound(actorIndexSeed, 0, _testActors.length - 1)];
        vm.startPrank(_currentTestActor);
        _;
        vm.stopPrank();
    }

    /**
     * @dev Modifier that ensures invariants are checked after the operation
     */
    modifier verifyInvariantsAfterOperation() {
        _;
        verifyAndResetInvariants();
    }

    /**
     * @dev Captures the current state before an operation
     *
     * This function records all relevant balances and state variables
     * that will be used to verify invariants after the operation completes.
     * It must be called before any operation that changes protocol state.
     */
    function captureInvariantState() internal virtual {
        // Capture protocol total assets
        _initialTotalAssets = ltv.totalAssets(true);
        // Get real total supply (can be affected by max growth fee)
        _initialTotalSupply = ltv.convertToShares(_initialTotalAssets);

        // Capture user balances
        _initialBorrowBalance = int256(IERC20(ltv.borrowToken()).balanceOf(_currentTestActor));
        _initialLtvBalance = int256(ltv.balanceOf(_currentTestActor));
        _initialCollateralBalance = int256(IERC20(ltv.collateralToken()).balanceOf(_currentTestActor));

        // Capture fee collector balances
        _initialFeeCollectorBorrowBalance = IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector());
        _initialFeeCollectorCollateralBalance = IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector());
        _initialFeeCollectorLtvBalance = ltv.balanceOf(ltv.feeCollector());

        // Capture protocol auction state
        _initialFutureCollateral = ltv.futureCollateralAssets();
        _initialFutureBorrow = ltv.futureBorrowAssets();
        _initialRewardBorrow = ltv.futureRewardBorrowAssets();
        _initialRewardCollateral = ltv.futureRewardCollateralAssets();
        _initialRealBorrow = _getRealBorrowAssets(false);
        _initialRealCollateral = _getRealCollateralAssets(false);

        _initialAuctionStartBlock = ltv.startAuction();

        _auctionExecuted = false;
        _invariantStateCaptured = true;
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
    function verifyAndResetInvariants() public virtual {
        if (!_invariantStateCaptured) {
            return;
        }

        // In case of auction execution sum of collateral assets and borrow assets should be the same.
        // The price check is omitted since it can decrease due to rounding, but real money amount remains the same
        if (_auctionExecuted) {
            assertGe(
                _initialFutureBorrow + _initialRewardBorrow + _initialRealBorrow,
                _getRealBorrowAssets(true) + ltv.futureRewardBorrowAssets() + ltv.futureBorrowAssets(),
                "Borrow assets stable after auction"
            );
            assertLe(
                _initialFutureCollateral + _initialRewardCollateral + _initialRealCollateral,
                _getRealCollateralAssets(true) + ltv.futureRewardCollateralAssets() + ltv.futureCollateralAssets(),
                "Collateral assets stable after auction"
            );
        } else {
            // Invariant 1: Token price never decreases
            // This ensures the protocol doesn't lose value for existing holders
            assertGe(
                ltv.totalAssets(true) * _initialTotalSupply,
                _initialTotalAssets * ltv.totalSupply(),
                "Token price became smaller"
            );
        }

        // Invariant 2: User balances change exactly as expected
        assertEq(
            int256(IERC20(ltv.borrowToken()).balanceOf(_currentTestActor)),
            _initialBorrowBalance + _expectedBorrowDelta,
            "Borrow balance changed"
        );
        assertEq(
            int256(IERC20(ltv.collateralToken()).balanceOf(_currentTestActor)),
            _initialCollateralBalance - _expectedCollateralDelta,
            "Collateral balance changed"
        );
        assertEq(
            int256(ltv.balanceOf(_currentTestActor)), _initialLtvBalance + _expectedLtvDelta, "LTV balance changed"
        );

        assertEq(ltv.balanceOf(address(ltv)), 0, "No missed ltv tokens");
        assertEq(IERC20(ltv.borrowToken()).balanceOf(address(ltv)), 0, "No missed borrow tokens");
        assertEq(IERC20(ltv.collateralToken()).balanceOf(address(ltv)), 0, "No missed collateral tokens");

        (uint256 initialBorrowReward, uint256 initialCollateralReward) =
            _getAuctionRewardsInLessPreciseAsset(_initialRewardBorrow, _initialRewardCollateral);
        (uint256 currentBorrowReward, uint256 currentCollateralReward) =
            _getAuctionRewardsInLessPreciseAsset(ltv.futureRewardBorrowAssets(), ltv.futureRewardCollateralAssets());

        // Check if auction was executed and rewards should be distributed
        // Multiply by 10 to account for rounding errors
        if (
            _initialAuctionStartBlock + ltv.auctionDuration() > uint56(block.number) && checkAuctionExecuted()
                && (
                    initialBorrowReward >= currentBorrowReward + 10 * uint256(ltv.auctionDuration())
                        || initialCollateralReward >= currentCollateralReward + 10 * uint256(ltv.auctionDuration())
                )
        ) {
            // Verify that fee collector received rewards
            assertTrue(
                _initialFeeCollectorBorrowBalance < IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector())
                    || _initialFeeCollectorCollateralBalance < IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector())
                    || _initialFeeCollectorLtvBalance < ltv.balanceOf(ltv.feeCollector()),
                "Auction rewards received"
            );
            auctionRewardsReceived = true;
        }

        // Invariant 4: Check for max growth fee application
        // This fee is applied when token price increases and user performs operations
        if (ltv.lastSeenTokenPrice() > _initialLastSeenTokenPrice) {
            assertLt(_initialFeeCollectorLtvBalance, ltv.balanceOf(ltv.feeCollector()), "Max growth fee applied");
            maxGrowthFeeReceived = true;
        }

        // Reset state for next operation
        _invariantStateCaptured = false;
    }

    /**
     * @dev Advances the blockchain by a specified number of blocks
     * @param blocksToAdvance Number of blocks to advance (bounded between 1 and auctionDuration)
     */
    function advanceBlocks(uint256 blocksToAdvance) internal {
        _initialLastSeenTokenPrice = ltv.lastSeenTokenPrice();
        _blocksAdvanced = bound(blocksToAdvance, 1, ltv.auctionDuration());
        vm.roll(uint56(block.number) + _blocksAdvanced);
    }

    /**
     * @dev Checks if an auction was executed during the operation
     * @return True if auction was executed, false otherwise
     */
    function checkAuctionExecuted() internal view returns (bool) {
        return (
            _initialFutureCollateral > 0 && _initialFutureCollateral > ltv.futureCollateralAssets()
                || _initialFutureCollateral < 0 && _initialFutureCollateral < ltv.futureCollateralAssets()
        );
    }

    function _getRealBorrowAssets(bool isDeposit) internal view returns (int256) {
        return int256(
            ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(
                isDeposit, ltv.lendingConnectorGetterData()
            )
        );
    }

    function _getRealCollateralAssets(bool isDeposit) internal view returns (int256) {
        return int256(
            ILendingConnector(ltv.getLendingConnector()).getRealCollateralAssets(
                isDeposit, ltv.lendingConnectorGetterData()
            )
        );
    }

    function _getAuctionRewardsInLessPreciseAsset(
        int256 _futureRewardBorrowAssets,
        int256 _futureRewardCollateralAssets
    ) internal view returns (uint256, uint256) {
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 futureRewardBorrowAssets = uint256(_futureRewardBorrowAssets);
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 futureRewardCollateralAssets = uint256(-_futureRewardCollateralAssets);
        uint256 borrowPrice =
            DummyOracleConnector(ltv.oracleConnector()).getPriceBorrowOracle(ltv.oracleConnectorGetterData());
        uint256 collateralPrice =
            DummyOracleConnector(ltv.oracleConnector()).getPriceCollateralOracle(ltv.oracleConnectorGetterData());
        uint256 borrowTokenDecimals = IERC20Metadata(ltv.borrowToken()).decimals();
        uint256 collateralTokenDecimals = IERC20Metadata(ltv.collateralToken()).decimals();

        if (borrowTokenDecimals > collateralTokenDecimals) {
            futureRewardBorrowAssets = futureRewardBorrowAssets.mulDivDown(borrowPrice, 10 ** borrowTokenDecimals)
                .mulDivDown(10 ** collateralTokenDecimals, collateralPrice);
        } else {
            futureRewardCollateralAssets = futureRewardCollateralAssets.mulDivDown(
                collateralPrice, 10 ** collateralTokenDecimals
            ).mulDivDown(10 ** borrowTokenDecimals, borrowPrice);
        }

        return (futureRewardBorrowAssets, futureRewardCollateralAssets);
    }
}
