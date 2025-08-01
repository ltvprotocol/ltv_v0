// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BaseInvariantWrapper} from "./BaseInvariantWrapper.t.sol";

/**
 * @title LTVVaultWrapper
 * @dev Wrapper contract for testing LTV vault operations (deposit/withdraw/mint/redeem)
 *
 * This contract extends BaseInvariantWrapper to provide fuzzable functions for
 * all vault operations. It ensures that:
 * - All operations respect maximum limits
 * - User balances are properly tracked
 * - Invariants are maintained after each operation
 * - Additional vault-specific invariants are verified
 *
 * The wrapper simulates realistic user interactions with the LTV vault,
 * including both borrow token and collateral token operations.
 */
abstract contract BaseVaultInvariantWrapper is BaseInvariantWrapper {
    /**
     * @dev Allows a user to deposit borrow tokens and receive LTV tokens
     * @param amount Amount to deposit (will be bounded by maxDeposit)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzDeposit(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed deposit for current actor
        uint256 maxDeposit = ltv.maxDeposit(_currentTestActor);

        // Ensure there's something to deposit
        vm.assume(maxDeposit > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxDeposit);

        // Ensure actor has enough borrow tokens
        if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < amount) {
            deal(ltv.borrowToken(), _currentTestActor, amount);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < amount) {
            IERC20(ltv.borrowToken()).approve(address(ltv), amount);
        }

        // Capture state before operation
        captureInvariantState();

        // Execute deposit and track changes
        _expectedLtvDelta = int256(ltv.deposit(amount, _currentTestActor));
        _expectedBorrowDelta = _expectedLtvDelta == 0 ? int256(0) : -int256(amount);
        _expectedCollateralDelta = 0;
    }

    /**
     * @dev Allows a user to withdraw borrow tokens by burning LTV tokens
     * @param amount Amount to withdraw (will be bounded by maxWithdraw)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzWithdraw(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed withdrawal for current actor
        uint256 maxWithdraw = ltv.maxWithdraw(_currentTestActor);
        vm.assume(maxWithdraw > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxWithdraw);

        // Capture state before operation
        captureInvariantState();

        // Execute withdrawal and track changes
        _expectedLtvDelta = -int256(ltv.withdraw(amount, _currentTestActor, _currentTestActor));
        _expectedBorrowDelta = _expectedLtvDelta == 0 ? int256(0) : int256(amount);
        _expectedCollateralDelta = 0;
    }

    /**
     * @dev Allows a user to mint LTV tokens by depositing borrow tokens
     * @param amount Amount of LTV tokens to mint (will be bounded by maxMint)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzMint(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed mint for current actor
        uint256 maxMint = ltv.maxMint(_currentTestActor);

        vm.assume(maxMint > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxMint);

        // Calculate required borrow tokens for minting
        uint256 assets = ltv.previewMint(amount);

        // Ensure actor has enough borrow tokens
        if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < assets) {
            deal(ltv.borrowToken(), _currentTestActor, assets);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < assets) {
            IERC20(ltv.borrowToken()).approve(address(ltv), assets);
        }

        // Capture state before operation
        captureInvariantState();

        // Execute mint and track changes
        _expectedBorrowDelta = -int256(ltv.mint(amount, _currentTestActor));
        _expectedLtvDelta = _expectedBorrowDelta == 0 ? int256(0) : int256(amount);
        _expectedCollateralDelta = 0;
    }

    /**
     * @dev Allows a user to redeem LTV tokens for borrow tokens
     * @param amount Amount of LTV tokens to redeem (will be bounded by maxRedeem)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzRedeem(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed redemption for current actor
        uint256 maxRedeem = ltv.maxRedeem(_currentTestActor);
        vm.assume(maxRedeem > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxRedeem);

        // Capture state before operation
        captureInvariantState();

        // Execute redemption and track changes
        _expectedBorrowDelta = int256(ltv.redeem(amount, _currentTestActor, _currentTestActor));
        _expectedLtvDelta = _expectedBorrowDelta == 0 ? int256(0) : -int256(amount);
        _expectedCollateralDelta = 0;
    }

    /**
     * @dev Allows a user to deposit collateral tokens and receive LTV tokens
     * @param amount Amount to deposit (will be bounded by maxDepositCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzDepositCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed collateral deposit for current actor
        uint256 maxDeposit = ltv.maxDepositCollateral(_currentTestActor);

        vm.assume(maxDeposit > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxDeposit);

        // Ensure actor has enough collateral tokens
        if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < amount) {
            deal(ltv.collateralToken(), _currentTestActor, amount);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv)) < amount) {
            IERC20(ltv.collateralToken()).approve(address(ltv), amount);
        }

        // Capture state before operation
        captureInvariantState();

        // Execute collateral deposit and track changes
        _expectedLtvDelta = int256(ltv.depositCollateral(amount, _currentTestActor));
        _expectedCollateralDelta = _expectedLtvDelta == 0 ? int256(0) : int256(amount);
        _expectedBorrowDelta = 0;
    }

    /**
     * @dev Allows a user to withdraw collateral tokens by burning LTV tokens
     * @param amount Amount to withdraw (will be bounded by maxWithdrawCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzWithdrawCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed collateral withdrawal for current actor
        uint256 maxWithdraw = ltv.maxWithdrawCollateral(_currentTestActor);
        vm.assume(maxWithdraw > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxWithdraw);

        // Capture state before operation
        captureInvariantState();

        // Execute collateral withdrawal and track changes
        _expectedLtvDelta = -int256(ltv.withdrawCollateral(amount, _currentTestActor, _currentTestActor));
        _expectedCollateralDelta = _expectedLtvDelta == 0 ? int256(0) : -int256(amount);
        _expectedBorrowDelta = 0;
    }

    /**
     * @dev Allows a user to mint LTV tokens by depositing collateral tokens
     * @param amount Amount of LTV tokens to mint (will be bounded by maxMintCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzMintCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed collateral mint for current actor
        uint256 maxMint = ltv.maxMintCollateral(_currentTestActor);

        vm.assume(maxMint > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxMint);

        // Calculate required collateral tokens for minting
        uint256 assets = ltv.previewMintCollateral(amount);

        // Ensure actor has enough collateral tokens
        if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < assets) {
            deal(ltv.collateralToken(), _currentTestActor, assets);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv)) < assets) {
            IERC20(ltv.collateralToken()).approve(address(ltv), assets);
        }

        // Capture state before operation
        captureInvariantState();

        // Execute collateral mint and track changes
        _expectedCollateralDelta = int256(ltv.mintCollateral(amount, _currentTestActor));
        _expectedLtvDelta = _expectedCollateralDelta == 0 ? int256(0) : int256(amount);
        _expectedBorrowDelta = 0;
    }

    /**
     * @dev Allows a user to redeem LTV tokens for collateral tokens
     * @param amount Amount of LTV tokens to redeem (will be bounded by maxRedeemCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function fuzzRedeemCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        // Advance blocks to simulate time passage
        advanceBlocks(blocksDelta);

        // Get maximum allowed collateral redemption for current actor
        uint256 maxRedeem = ltv.maxRedeemCollateral(_currentTestActor);
        vm.assume(maxRedeem > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxRedeem);

        // Capture state before operation
        captureInvariantState();

        // Execute collateral redemption and track changes
        _expectedCollateralDelta = -int256(ltv.redeemCollateral(amount, _currentTestActor, _currentTestActor));
        _expectedLtvDelta = _expectedCollateralDelta == 0 ? int256(0) : -int256(amount);
        _expectedBorrowDelta = 0;
    }

    /**
     * @dev Override of verifyAndResetInvariants to add vault-specific invariant checks
     *
     * Invariants enforced:
     * - If either future borrow or future collateral assets is nonzero, both must be nonzero (never only one is nonzero)
     * - If future borrow assets is zero, then future reward borrow assets must also be zero
     * - If future collateral assets is zero, then future reward collateral assets must also be zero
     */
    function verifyAndResetInvariants() public virtual override {
        // Call parent invariant checking
        super.verifyAndResetInvariants();

        // Invariant: future borrow and collateral assets must both be zero or both be nonzero
        assertTrue(
            (ltv.futureBorrowAssets() != 0 && ltv.futureCollateralAssets() != 0)
                || ltv.futureCollateralAssets() == ltv.futureBorrowAssets(),
            "Future borrow and collateral assets must both be zero or both nonzero"
        );

        // Invariant: if future borrow assets is zero, reward borrow assets must also be zero
        assertTrue(
            (ltv.futureBorrowAssets() != 0) || ltv.futureRewardBorrowAssets() == 0,
            "If future borrow assets is zero, reward borrow assets must also be zero"
        );

        // Invariant: if future collateral assets is zero, reward collateral assets must also be zero
        assertTrue(
            (ltv.futureCollateralAssets() != 0) || ltv.futureRewardCollateralAssets() == 0,
            "If future collateral assets is zero, reward collateral assets must also be zero"
        );

        assertTrue(
            ltv.futureBorrowAssets() <= 0 || ltv.futureRewardBorrowAssets() == 0,
            "Future reward is in collateral when positive auction"
        );

        assertTrue(
            ltv.futureCollateralAssets() >= 0 || ltv.futureRewardCollateralAssets() == 0,
            "Future reward is in borrow when negative auction"
        );
    }
}

contract VaultInvariantWrapper is BaseVaultInvariantWrapper {
    constructor(ILTV _ltv, address[10] memory _actors) BaseInvariantWrapper(_ltv, _actors) {}
}
