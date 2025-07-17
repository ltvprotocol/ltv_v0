// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BasicInvariantWrapper} from "./BasicInvariantWrapper.t.sol";

/**
 * @title LTVVaultWrapper
 * @dev Wrapper contract for testing LTV vault operations (deposit/withdraw/mint/redeem)
 * 
 * This contract extends BasicInvariantWrapper to provide fuzzable functions for
 * all vault operations. It ensures that:
 * - All operations respect maximum limits
 * - User balances are properly tracked
 * - Invariants are maintained after each operation
 * - Additional vault-specific invariants are verified
 * 
 * The wrapper simulates realistic user interactions with the LTV vault,
 * including both borrow token and collateral token operations.
 */
contract LTVVaultWrapper is BasicInvariantWrapper {
    /**
     * @dev Constructor initializes the vault wrapper
     * @param _ltv The LTV protocol contract
     * @param _actors Array of test actors
     */
    constructor(ILTV _ltv, address[10] memory _actors) BasicInvariantWrapper(_ltv, _actors) {}

    /**
     * @dev Allows a user to deposit borrow tokens and receive LTV tokens
     * @param amount Amount to deposit (will be bounded by maxDeposit)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function deposit(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed deposit for current actor
        uint256 maxDeposit = ltv.maxDeposit(currentActor);

        // Ensure there's something to deposit
        vm.assume(maxDeposit > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxDeposit);

        // Ensure actor has enough borrow tokens
        if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < amount) {
            deal(ltv.borrowToken(), currentActor, amount);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.borrowToken()).approve(address(ltv), amount);
        }

        // Capture state before operation
        getInvariantsData();
        
        // Execute deposit and track changes
        deltaLtv = int256(ltv.deposit(amount, currentActor));
        deltaBorrow = deltaLtv == 0 ? int256(0) : -int256(amount);
        deltaCollateral = 0;
    }

    /**
     * @dev Allows a user to withdraw borrow tokens by burning LTV tokens
     * @param amount Amount to withdraw (will be bounded by maxWithdraw)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function withdraw(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed withdrawal for current actor
        uint256 maxWithdraw = ltv.maxWithdraw(currentActor);
        vm.assume(maxWithdraw > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxWithdraw);

        // Capture state before operation
        getInvariantsData();
        
        // Execute withdrawal and track changes
        deltaLtv = -int256(ltv.withdraw(amount, currentActor, currentActor));
        deltaBorrow = deltaLtv == 0 ? int256(0) : int256(amount);
        deltaCollateral = 0;
    }

    /**
     * @dev Allows a user to mint LTV tokens by depositing borrow tokens
     * @param amount Amount of LTV tokens to mint (will be bounded by maxMint)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function mint(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed mint for current actor
        uint256 maxMint = ltv.maxMint(currentActor);

        vm.assume(maxMint > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxMint);

        // Calculate required borrow tokens for minting
        uint256 assets = ltv.previewMint(amount);
        
        // Ensure actor has enough borrow tokens
        if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < assets) {
            deal(ltv.borrowToken(), currentActor, assets);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < assets) {
            IERC20(ltv.borrowToken()).approve(address(ltv), assets);
        }

        // Capture state before operation
        getInvariantsData();
        
        // Execute mint and track changes
        deltaBorrow = -int256(ltv.mint(amount, currentActor));
        deltaLtv = deltaBorrow == 0 ? int256(0) : int256(amount);
        deltaCollateral = 0;
    }

    /**
     * @dev Allows a user to redeem LTV tokens for borrow tokens
     * @param amount Amount of LTV tokens to redeem (will be bounded by maxRedeem)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function redeem(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed redemption for current actor
        uint256 maxRedeem = ltv.maxRedeem(currentActor);
        vm.assume(maxRedeem > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxRedeem);

        // Capture state before operation
        getInvariantsData();
        
        // Execute redemption and track changes
        deltaBorrow = int256(ltv.redeem(amount, currentActor, currentActor));
        deltaLtv = deltaBorrow == 0 ? int256(0) : -int256(amount);
        deltaCollateral = 0;
    }

    /**
     * @dev Allows a user to deposit collateral tokens and receive LTV tokens
     * @param amount Amount to deposit (will be bounded by maxDepositCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function depositCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed collateral deposit for current actor
        uint256 maxDeposit = ltv.maxDepositCollateral(currentActor);

        vm.assume(maxDeposit > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxDeposit);

        // Ensure actor has enough collateral tokens
        if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < amount) {
            deal(ltv.collateralToken(), currentActor, amount);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.collateralToken()).approve(address(ltv), amount);
        }

        // Capture state before operation
        getInvariantsData();
        
        // Execute collateral deposit and track changes
        deltaLtv = int256(ltv.depositCollateral(amount, currentActor));
        deltaCollateral = deltaLtv == 0 ? int256(0) : int256(amount);
        deltaBorrow = 0;
    }

    /**
     * @dev Allows a user to withdraw collateral tokens by burning LTV tokens
     * @param amount Amount to withdraw (will be bounded by maxWithdrawCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function withdrawCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed collateral withdrawal for current actor
        uint256 maxWithdraw = ltv.maxWithdrawCollateral(currentActor);
        vm.assume(maxWithdraw > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxWithdraw);

        // Capture state before operation
        getInvariantsData();
        
        // Execute collateral withdrawal and track changes
        deltaLtv = -int256(ltv.withdrawCollateral(amount, currentActor, currentActor));
        deltaCollateral = deltaLtv == 0 ? int256(0) : -int256(amount);
        deltaBorrow = 0;
    }

    /**
     * @dev Allows a user to mint LTV tokens by depositing collateral tokens
     * @param amount Amount of LTV tokens to mint (will be bounded by maxMintCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function mintCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed collateral mint for current actor
        uint256 maxMint = ltv.maxMintCollateral(currentActor);

        vm.assume(maxMint > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxMint);

        // Calculate required collateral tokens for minting
        uint256 assets = ltv.previewMintCollateral(amount);
        
        // Ensure actor has enough collateral tokens
        if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < assets) {
            deal(ltv.collateralToken(), currentActor, assets);
        }

        // Ensure actor has approved the LTV contract
        if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < assets) {
            IERC20(ltv.collateralToken()).approve(address(ltv), assets);
        }

        // Capture state before operation
        getInvariantsData();
        
        // Execute collateral mint and track changes
        deltaCollateral = int256(ltv.mintCollateral(amount, currentActor));
        deltaLtv = deltaCollateral == 0 ? int256(0) : int256(amount);
        deltaBorrow = 0;
    }

    /**
     * @dev Allows a user to redeem LTV tokens for collateral tokens
     * @param amount Amount of LTV tokens to redeem (will be bounded by maxRedeemCollateral)
     * @param actorIndexSeed Fuzzer seed to select actor
     * @param blocksDelta Number of blocks to advance before operation
     */
    function redeemCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        makePostCheck
    {
        // Advance blocks to simulate time passage
        moveBlock(blocksDelta);
        
        // Get maximum allowed collateral redemption for current actor
        uint256 maxRedeem = ltv.maxRedeemCollateral(currentActor);
        vm.assume(maxRedeem > 0);

        // Bound the amount to valid range
        amount = bound(amount, 1, maxRedeem);

        // Capture state before operation
        getInvariantsData();
        
        // Execute collateral redemption and track changes
        deltaCollateral = -int256(ltv.redeemCollateral(amount, currentActor, currentActor));
        deltaLtv = deltaCollateral == 0 ? int256(0) : -int256(amount);
        deltaBorrow = 0;
    }

    /**
     * @dev Override of checkAndResetInvariants to add vault-specific invariant checks
     *
     * Invariants enforced:
     * - If either future borrow or future collateral assets is nonzero, both must be nonzero (never only one is nonzero)
     * - If future borrow assets is zero, then future reward borrow assets must also be zero
     * - If future collateral assets is zero, then future reward collateral assets must also be zero
     */
    function checkAndResetInvariants() public override {
        // Call parent invariant checking
        super.checkAndResetInvariants();
        
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
    }
}
