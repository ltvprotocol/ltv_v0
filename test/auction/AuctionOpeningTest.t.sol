// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract AuctionsOpeningTest is BaseTest {
    uint256 constant STEPS = 1000;
    uint256 constant TARGET_DELTA = 4;
    uint256 constant TOLERANCE = 2;
    uint256 constant GIVEN_AMOUNT = 1_000_000;

    function assertDeltaInCorrectRange(uint256 delta) public pure {
        assertGe(delta, TARGET_DELTA - TOLERANCE);
        assertLe(delta, TARGET_DELTA + TOLERANCE);
    }

    modifier positiveAuctionTest() {
        BaseTestInit memory initData = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 16_000_000,
            futureCollateral: 16_000_000,
            auctionReward: -16_000,
            startAuction: 1000,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 984_016_000,
            borrowAssets: 734_000_000,
            maxSafeLTVDividend: 9,
            maxSafeLTVDivider: 10,
            minProfitLTVDividend: 5,
            minProfitLTVDivider: 10,
            targetLTVDividend: 75,
            targetLTVDivider: 100,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            collateralPrice: 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            zeroAddressTokens: 984016000 + 16000000 - 734000000 - 16000000 - 16_000
        });
        // The zero address holds the excess token balance to balance the system.
        // This ensures the initial price of the protocol's token is 1.
        // Computed as: collateralAssets + futureCollateral - borrowAssets - futureBorrow - auctionReward.

        initializeTest(initData);

        // Verify the 3:4 ratio relationship between collateral and borrow assets.
        // It's needed to make sure that vault configuration is correct.
        assertEq(
            (
                int256(ltv.getRealCollateralAssets(false)) + ltv.futureCollateralAssets()
                    + ltv.futureRewardCollateralAssets()
            ) * 3,
            (int256(ltv.getRealBorrowAssets(false)) + ltv.futureBorrowAssets() + ltv.futureRewardBorrowAssets()) * 4
        );
        vm.pauseGasMetering();
        _;
    }

    modifier negativeAuctionTest() {
        BaseTestInit memory initData = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: -16_000_000,
            futureCollateral: -16_000_000,
            auctionReward: 16_000,
            startAuction: 1000,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 1_016_000_000,
            borrowAssets: 765_984_000,
            maxSafeLTVDividend: 9,
            maxSafeLTVDivider: 10,
            minProfitLTVDividend: 5,
            minProfitLTVDivider: 10,
            targetLTVDividend: 75,
            targetLTVDivider: 100,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            collateralPrice: 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            zeroAddressTokens: 1_016_000_000 + 16000000 - 765_984_000 - 16000000 - 16_000
        });
        // The zero address holds the excess token balance to balance the system.
        // This ensures the initial price of the protocol's token is 1.
        // Computed as: collateralAssets + futureCollateral - borrowAssets - futureBorrow - auctionReward.

        initializeTest(initData);

        // Verify the 3:4 ratio relationship between collateral and borrow assets.
        // It's needed to make sure that vault configuration is correct.
        assertEq(
            (
                int256(ltv.getRealCollateralAssets(false)) + ltv.futureCollateralAssets()
                    + ltv.futureRewardCollateralAssets()
            ) * 3,
            (int256(ltv.getRealBorrowAssets(false)) + ltv.futureBorrowAssets() + ltv.futureRewardBorrowAssets()) * 4
        );
        vm.pauseGasMetering();
        _;
    }

    // take a borrow with a positive auction:

    function test_withdrawBecomesMoreProfitableDuringAuctionOpening() public positiveAuctionTest {
        uint256 prevShares = ltv.previewWithdraw(GIVEN_AMOUNT);
        uint256 currentShares;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentShares = ltv.previewWithdraw(GIVEN_AMOUNT);
            // checks that each step needed less and less shares to withdraw GIVEN_AMOUNT of assets
            assertLt(currentShares, prevShares);

            uint256 delta = prevShares - currentShares;
            assertDeltaInCorrectRange(delta);

            prevShares = currentShares;
        }
    }

    function test_redeemBecomesMoreProfitableDuringAuctionOpening() public positiveAuctionTest {
        uint256 prevAssets = ltv.previewRedeem(GIVEN_AMOUNT);
        uint256 currentAssets;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentAssets = ltv.previewRedeem(GIVEN_AMOUNT);
            // checks that each step user receives more and more assets for GIVEN_AMOUNT of shares
            assertGt(currentAssets, prevAssets);

            uint256 delta = currentAssets - prevAssets;
            assertDeltaInCorrectRange(delta);

            prevAssets = currentAssets;
        }
    }

    // take a collateral with a positive auction:

    function test_withdrawCollateralBecomesMoreProfitableDuringAuctionOpening() public positiveAuctionTest {
        uint256 prevShares = ltv.previewWithdrawCollateral(GIVEN_AMOUNT);
        uint256 currentShares;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentShares = ltv.previewWithdrawCollateral(GIVEN_AMOUNT);
            // checks that each step needed less and less shares to withdraw GIVEN_AMOUNT of assets
            assertLt(currentShares, prevShares);

            uint256 delta = prevShares - currentShares;
            assertDeltaInCorrectRange(delta);

            prevShares = currentShares;
        }
    }

    function test_redeemCollateralBecomesMoreProfitableDuringAuctionOpening() public positiveAuctionTest {
        uint256 prevAssets = ltv.previewRedeemCollateral(GIVEN_AMOUNT);
        uint256 currentAssets;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentAssets = ltv.previewRedeemCollateral(GIVEN_AMOUNT);
            // checks that each step user receives more and more assets for GIVEN_AMOUNT of shares
            assertGt(currentAssets, prevAssets);

            uint256 delta = currentAssets - prevAssets;
            assertDeltaInCorrectRange(delta);

            prevAssets = currentAssets;
        }
    }

    // bring a borrow with a negative auction:

    function test_depositBecomesMoreProfitableDuringAuctionOpening() public negativeAuctionTest {
        uint256 prevShares = ltv.previewDeposit(GIVEN_AMOUNT);
        uint256 currentShares;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentShares = ltv.previewDeposit(GIVEN_AMOUNT);
            // checks that each step user receives more and more shares for GIVEN_AMOUNT of assets
            assertGt(currentShares, prevShares);

            uint256 delta = currentShares - prevShares;
            assertDeltaInCorrectRange(delta);

            prevShares = currentShares;
        }
    }

    function test_mintBecomesMoreProfitableDuringAuctionOpening() public negativeAuctionTest {
        uint256 prevAssets = ltv.previewMint(GIVEN_AMOUNT);
        uint256 currentAssets;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentAssets = ltv.previewMint(GIVEN_AMOUNT);
            // checks that each step needed less and less assets to mint GIVEN_AMOUNT of shares
            assertLt(currentAssets, prevAssets);

            uint256 delta = prevAssets - currentAssets;
            assertDeltaInCorrectRange(delta);

            prevAssets = currentAssets;
        }
    }

    // bring a collateral with a negative auction:

    function test_depositCollateralBecomesMoreProfitableDuringAuctionOpening() public negativeAuctionTest {
        uint256 prevShares = ltv.previewDepositCollateral(GIVEN_AMOUNT);
        uint256 currentShares;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentShares = ltv.previewDepositCollateral(GIVEN_AMOUNT);
            // checks that each step user receives more and more shares for GIVEN_AMOUNT of assets
            assertGt(currentShares, prevShares);

            uint256 delta = currentShares - prevShares;
            assertDeltaInCorrectRange(delta);

            prevShares = currentShares;
        }
    }

    function test_mintCollateralBecomesMoreProfitableDuringAuctionOpening() public negativeAuctionTest {
        uint256 prevAssets = ltv.previewMintCollateral(GIVEN_AMOUNT);
        uint256 currentAssets;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentAssets = ltv.previewMintCollateral(GIVEN_AMOUNT);
            // checks that each step needed less and less assets to mint GIVEN_AMOUNT of shares
            assertLt(currentAssets, prevAssets);

            uint256 delta = prevAssets - currentAssets;
            assertDeltaInCorrectRange(delta);

            prevAssets = currentAssets;
        }
    }
}
