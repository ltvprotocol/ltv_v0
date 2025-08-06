// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BaseTest.t.sol";

/**
 * @title SharePriceOnStaticVaultTestNegativeAuctionCollateral
 * @dev This contract tests token pricing behavior for projected deposits and withdrawals collateral
 * tokens in a static vault state with negative auction (negative futureBorrow/futureCollateral and positive auction reward).
 * It focuses on how the vault handles different cases of our math and edge points on case change.
 */
contract SharePriceOnStaticVaultTestNegativeAuctionCollateral is BaseTest {
    uint256 constant CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT = 4_800_000;
    uint256 constant CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT = 4_875_000;
    uint256 constant ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT = 7_375_000;
    uint256 constant ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT = 7_375_000;

    // Number of test iterations to run within a 10-second timeframe
    uint256 constant TEN_SECONDS_TEST_ITERATION_AMOUNT = 15564;

    modifier negativeAuctionTest() {
        BaseTestInit memory initData = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: -15_000_000,
            futureCollateral: -15_000_000,
            auctionReward: 150_000,
            startAuction: 500,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 991_000_000,
            borrowAssets: 746_850_000,
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
            zeroAddressTokens: 991_000_000 + 15_000_000 - 746_850_000 - 15_000_000 - 150_000
        });
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

    /**
     * @dev Test stable pricing behavior for redeems in static vault state
     *
     * This test verifies consistent price calculation for redeems in cmcb case
     */
    function test_caseDynamicNegativeAuctionStableRateCollateral() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 newAssets = ltv.previewRedeemCollateral(i);

            assertEq(newAssets, i * 32 / 33);
        }
    }

    /**
     * @dev Test stable pricing behavior for withdraws in static vault state
     *
     * This test verifies consistent price calculation for withdraws in cmcb case
     */
    function test_caseDynamicNegativeAuctionStableRateWithdrawCollateral() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 newShares = ltv.previewWithdrawCollateral(i);
            uint256 roundedUpExpectedShares = (i * 33 + 31) / 32;

            assertEq(newShares, roundedUpExpectedShares);
        }
    }

    /**
     * @dev Test makes sure cecb case is working correctly and checking switch to cecbc case.
     * Makes sure that share price starts to decrease after case change point to the 0.961165048
     */
    function test_caseDynamicNegativeAuctionDynamicRateCollateral() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        uint256 step = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that deposit pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT; i += step) {
            uint256 newShares = ltv.previewDepositCollateral(i);

            assertEq(i * caseChangePointShares / caseChangePointAssets, newShares);
        }

        // Test that deposit pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + step; i < 80_000_000; i += step) {
            uint256 newShares = ltv.previewDepositCollateral(i);

            // deposit benefit decreases with each step
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGt(i * oldShares, oldAssets * newShares);

            oldAssets = i;
            oldShares = newShares;
        }

        // Verify bounds for large deposit:
        // - deposit pricing should not drop below 97% for 80M shares
        // - Price should approach 0.97087378640...% asymptotically

        uint256 amount = 80_000_000;
        uint256 shares = ltv.previewDepositCollateral(amount);
        assertLt(shares, amount * 974 / 1000); // REAL COEFFICIENT HERE = 0.97355885

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigShares = ltv.previewDepositCollateral(bigAmount);
        assertGt(bigShares, bigAmount * 970_873 / 1_000_000);
        assertLt(bigShares, bigAmount * 970_874 / 1_000_000);
    }

    function test_caseDynamicNegativeAuctionDynamicRateMint() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        uint256 step = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that mint pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT; i += step) {
            uint256 newAssets = ltv.previewMintCollateral(i);
            uint256 expectedAssets = (i * caseChangePointAssets + caseChangePointShares - 1) / caseChangePointShares;

            assertGe(newAssets, expectedAssets);
        }

        // Test that mint pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT + step; i < 80_000_000; i += step) {
            uint256 newAssets = ltv.previewMintCollateral(i);

            // mint pricing is increasing each step (need more assets per share)
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGt(newAssets * oldShares, oldAssets * i);

            oldShares = i;
            oldAssets = newAssets;
        }

        // Verify bounds for large deposit:
        // - deposit pricing should not drop below 97.0% for 80M shares
        // - Price should approach 97.087378640% asymptotically

        uint256 amount = 80_000_000;
        uint256 assets = ltv.previewMintCollateral(amount);

        assertLt(assets, amount * 1_000 / 970);

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigAssets = ltv.previewMintCollateral(bigAmount);

        assertGt(bigAssets, bigAmount * 1_000_000 / 970_874);
        assertLt(bigAssets, bigAmount * 1_000_000 / 970_873);
    }

    /**
     * @dev Test the zero reward point area where deposit pricing bonus transitions to zero
     *
     * This test focuses on the critical area around 41_200_00 assets where
     * the pricing bonus becomes zero. The test verifies:
     *
     * 1. Deposit pricing is still favorable (assets > shares) before the zero point
     * 2. Deposit pricing increases monotonically in this region
     * 3. Deposit pricing never exceeds 1:1 (assets <= shares) before the zero point
     * 4. Deposit pricing exceeds 1:1 immediately after the zero point
     *
     * This ensures a smooth transition from bonus pricing to neutral/penalty pricing
     */
    function test_zeroRewardNegativeAuctionPointAreaCollateral() public negativeAuctionTest {
        uint256 oldAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;
        uint256 oldShares = ltv.previewDepositCollateral(oldAssets);

        // Test the transition area around the zero reward point
        // Verify that the deposit pricing increases smoothly and never
        // goes above 1:1 before the critical point, ensuring fair treatment

        for (
            uint256 i = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 shares = ltv.previewDepositCollateral(i);

            // deposit benefit decreases with each step
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGe(i * oldShares, oldAssets * shares);

            oldAssets = i;
            oldShares = shares;

            // test that deposit pricing is never less than 1
            assertGe(shares, i);
        }

        // Verify that immediately after the zero reward point,
        // the deposit pricing exceeds 1:1

        uint256 nextPointAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        uint256 nextPointShares = ltv.previewDepositCollateral(nextPointAssets);
        assertLt(nextPointShares, nextPointAssets);
    }

    function test_zeroRewardNegativeAuctionPointAreaMintCollateral() public negativeAuctionTest {
        uint256 oldShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT - 100;
        uint256 oldAssets = ltv.previewMintCollateral(oldShares);

        // Test the transition area around the zero reward point
        // Verify that the deposit pricing increases smoothly and never
        // goes above 1:1 before the critical point, ensuring fair treatment

        for (
            uint256 i = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT - 100;
            i <= ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 newAssets = ltv.previewMintCollateral(i);

            // test that deposit pricing is decreasing
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGe(newAssets * oldShares, oldAssets * i);

            oldShares = i;
            oldAssets = newAssets;

            assertLe(newAssets, i);
        }

        // Verify that immediately after the zero reward point,
        // the deposit pricing exceeds 1:1
        uint256 nextPointShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT + 1;
        uint256 nextPointAssets = ltv.previewMintCollateral(nextPointShares);
        assertLt(nextPointShares, nextPointAssets);
    }

    /**
     * @dev Test the case switch from cecb to cecbc. Makes sure that price is stable up to the case change point
     * and then drops immediately after the case change point.
     */
    function test_caseSwithNegativeAuctionPointAreaCollateral() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship

        for (
            uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 shares = ltv.previewDepositCollateral(i);
            // test that deposit pricing is stable
            assertEq(i * caseChangePointShares / caseChangePointAssets, shares);
        }

        assertEq(
            ltv.previewDepositCollateral(CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT),
            CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT
        );

        // Verify that the deposit immediately becomes less profitable after the case change point
        uint256 nextPointAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        uint256 nextPointShares = ltv.previewDepositCollateral(nextPointAssets);
        assertLt(nextPointShares * caseChangePointAssets, nextPointAssets * caseChangePointShares);
    }

    function test_caseSwithNegativeAuctionPointAreaMintCollateral() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship

        for (
            uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT - 100;
            i <= CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 newAssets = ltv.previewMintCollateral(i);
            uint256 expectedAssets = (i * caseChangePointAssets + caseChangePointShares - 1) / caseChangePointShares;

            assertGe(newAssets, expectedAssets);
        }

        // Verify that the mint immediately becomes less profitable after the case change point
        uint256 nextPointShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT + 1;
        uint256 nextPointAssets = ltv.previewMintCollateral(nextPointShares);
        assertLt(nextPointShares, nextPointAssets * caseChangePointShares / caseChangePointAssets);
    }
}
