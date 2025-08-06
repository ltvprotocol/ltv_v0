// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BaseTest.t.sol";

/**
 * @title SharePriceOnStaticVaultTest
 * @dev This contract tests token pricing behavior for projected deposits and withdrawals
 * in a static vault state. It focuses on how the vault handles different cases of our math and
 * edge points on case change.
 */
contract SharePriceOnStaticVaultTestPositiveAuction is BaseTest {
    // Point where case changes from cebc to ceccb
    uint256 private constant CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT = 4004000;

    // Point where the positive pricing bonus becomes zero. At this point bonus from
    // cebc case fully dissapears because of payments for ceccb case.
    uint256 private constant ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT = 4204000;

    // Number of test iterations to run within a 10-second timeframe
    uint256 private constant TEN_SECONDS_TEST_ITERATION_AMOUNT = 15564;

    /**
     * @dev For current vault state cmbc case delta future auction will be calculated as
     * x * PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDEND / PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDER.
     * To calculate projected payment, we need to divide this value by slippage precision(100) and round it up. So user will
     * have to give as payment about 3.88349% of deposited assets
     */
    uint256 private constant PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDEND = 400;
    uint256 private constant PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDER = 103;

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
            startAuction: 500,
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
     * @dev Test stable pricing behavior for deposits in static vault state
     *
     * This test verifies consistent price calculation for deposits in cmbc case
     */
    function test_caseDynamicPositiveAuctionStableRate() public positiveAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 shares = ltv.previewDeposit(i);

            assertEq(
                shares,
                i
                    - (
                        (
                            i * PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDEND
                                + PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDER - 1
                        ) / PROJECTED_AUCTION_SIZE_DEPOSIT_AUCTION_MERGING_DIVIDER + 99
                    ) / 100
            );
        }
    }

    function test_caseDynamicPositiveAuctionStableRateMint() public positiveAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 assets = ltv.previewMint(i);

            assertEq(assets, i + ((((i * 404040405) / 100000000) + 99) / 100));
        }
    }

    /**
     * @dev Test makes sure cebc case is working correctly and checking switch to ceccb case.
     * Makes sure that share price starts to decrease after case change point to the 0.958333
     */
    function test_caseDynamicPositiveAuctionDynamicRate() public positiveAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This point represents the most precise exchange rate on the [0, CASE_CHANGE_POINT] interval
        // and serves as the baseline for smaller withdrawal pricing
        uint256 caseChangePointAssets = ltv.previewRedeem(CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT);
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;

        uint256 step = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that withdrawal pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT; i += step) {
            uint256 assets = ltv.previewRedeem(i);

            assertEq(i * caseChangePointAssets / caseChangePointShares, assets);
        }

        // Verify the pricing bonus is within expected bounds (0.199% to 0.2%)
        assertGt(caseChangePointAssets * 100000, caseChangePointShares * 100199);
        assertLt(caseChangePointAssets * 1000, caseChangePointShares * 1002);

        // Test that withdrawal pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;
        uint256 initialAssets = caseChangePointAssets;
        uint256 initialShares = caseChangePointShares;
        for (uint256 i = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT + step; i < 80_000_000; i += step) {
            uint256 assets = ltv.previewRedeem(i);

            // withdrawal pricing is decreasing each step
            assertLt(assets * initialShares, initialAssets * i);
            initialAssets = assets;
            initialShares = i;
        }

        // Verify bounds for large withdrawals:
        // - Withdrawal pricing should not drop below 96.5% for 80M shares
        // - Price should approach 96% asymptotically
        assertLt(ltv.previewRedeem(80_000_000), 80_000_000 * 965 / 1000);

        assertGt(ltv.previewRedeem(80_000_000_000_000_000), 80_000_000_000_000_000 * 96 / 100);
        assertLt(ltv.previewRedeem(80_000_000_000_000_000), 80_000_000_000_000_000 * 9_600_001 / 10_000_000);
    }

    function test_caseDynamicPositiveAuctionDynamicRateWithdraw() public positiveAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This point represents the most precise exchange rate on the [0, CASE_CHANGE_POINT] interval
        // and serves as the baseline for smaller withdrawal pricing

        uint256 caseChangePointAssets = ltv.previewRedeem(CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT);
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;

        uint256 step = caseChangePointAssets * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that withdrawal pricing remains stable before the case change point
        for (uint256 i = 100; i < caseChangePointAssets; i += step) {
            uint256 currentShares = ltv.previewWithdraw(i);

            uint256 roundedUp = (i * caseChangePointShares + (caseChangePointAssets - 1)) / caseChangePointAssets;
            assertEq(roundedUp, currentShares);
        }

        // Verify the pricing bonus is within expected bounds (0.199% to 0.2%)
        assertGt(caseChangePointAssets * 100000, caseChangePointShares * 100199);
        assertLt(caseChangePointAssets * 1000, caseChangePointShares * 1002);

        // Test that withdrawal pricing decreases after the case change point
        step = (80_000_000 - caseChangePointAssets) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;
        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = caseChangePointAssets + step; i < 80_000_000; i += step) {
            uint256 newShares = ltv.previewWithdraw(i);

            /*
            * each next withdraw requires more shares for withdrawal
            * in percentage ratio with how much the previous one required
            */

            // newShares / newAssets > oldShares / oldAssets
            // newShares * oldAssets > oldShares * newAssets
            assertGt(newShares * oldAssets, oldShares * i);

            oldAssets = i;
            oldShares = newShares;
        }

        // Verify bounds for large withdrawals:
        // - Withdrawal pricing should not drop below 96.2% for 80M shares
        // - Price should approach 96% asymptotically

        uint256 amount = 80_000_000;
        uint256 shares = ltv.previewWithdraw(amount);

        assertLt(shares, amount * 1000 / 962);

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigShares = ltv.previewWithdraw(bigAmount);

        assertGt(bigShares, bigAmount * 10000000 / 9600001);
        assertLt(bigShares, bigAmount * 100 / 96);
    }

    /**
     * @dev Test the zero reward point area where withdrawal pricing bonus transitions to zero
     *
     * This test focuses on the critical area around 4,204,000 shares where
     * the positive pricing bonus becomes zero. The test verifies:
     *
     * 1. Withdrawal pricing is still favorable (assets > shares) before the zero point
     * 2. Withdrawal pricing decreases monotonically in this region
     * 3. Withdrawal pricing never drops below 1:1 (assets >= shares) before the zero point
     * 4. Withdrawal pricing drops below 1:1 immediately after the zero point
     *
     * This ensures a smooth transition from bonus pricing to neutral/penalty pricing
     */
    function test_zeroRewardPositiveAuctionPointArea() public positiveAuctionTest {
        uint256 initialAssets = ltv.previewRedeem(ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT - 100);
        uint256 initialShares = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT - 100;
        assertGt(initialAssets, initialShares);

        // Test the transition area around the zero reward point
        // Verify that the withdrawal pricing decreases smoothly and never
        // goes below 1:1 before the critical point, ensuring fair treatment
        for (
            uint256 i = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT - 100;
            i <= ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 assets = ltv.previewRedeem(i);
            // test that withdrawal pricing is decreasing

            // assets_new / shares_new < assets_old / shares_old
            // assets_new * shares_old < assets_old * shares_new
            assertLe(assets * initialShares, initialAssets * i);
            initialAssets = assets;
            initialShares = i;
            // test that withdrawal pricing is never less than 1
            assertGe(assets, i);
        }

        // Verify that immediately after the zero reward point,
        // the withdrawal pricing drops below 1:1
        uint256 nextPoint = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT + 1;
        assertLt(ltv.previewRedeem(nextPoint), nextPoint);
    }

    function test_zeroRewardPositiveAuctionPointAreaWithdraw() public positiveAuctionTest {
        uint256 assetsCaseChangePoint = ltv.previewRedeem(ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT);

        uint256 oldAssets = assetsCaseChangePoint - 100;
        uint256 oldShares = ltv.previewWithdraw(oldAssets);
        assertGt(oldAssets, oldShares);

        // Test the transition area around the zero reward point
        // Verify that the withdrawal pricing decreases smoothly and never
        // goes below 1:1 before the critical point, ensuring fair treatment
        for (uint256 i = assetsCaseChangePoint - 100; i <= assetsCaseChangePoint; ++i) {
            uint256 newShares = ltv.previewWithdraw(i);
            // test that withdrawal pricing is decreasing

            // newShares / newAssets > oldShares / oldAssets
            // newShares * oldAssets > oldShares * newAssets
            assertGe(newShares * oldAssets, oldShares * i);

            oldAssets = i;
            oldShares = newShares;

            // test that withdrawal pricing is never less than 1
            assertGe(i, newShares);
        }

        // Verify that immediately after the zero reward point,
        // the withdrawal pricing drops below 1:1
        uint256 zeroRewardPositiveAuctionAssetsPoint = ltv.previewRedeem(ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT);
        uint256 nextPoint = zeroRewardPositiveAuctionAssetsPoint + 1;
        assertLt(nextPoint, ltv.previewWithdraw(nextPoint));
    }

    /**
     * @dev Test the case switch from cebc to ceccb. Makes sure that price is stable up to the case change point
     * and then drops immediately after the case change point.
     */
    function test_caseSwithPositiveAuctionPointArea() public positiveAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This represents the most precise exchange rate on the stable interval
        // and serves as the baseline for pricing calculations
        uint256 caseChangePointAssets = ltv.previewRedeem(CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT);
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship
        for (
            uint256 i = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT - 100;
            i <= CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 assets = ltv.previewRedeem(i);
            // test that withdrawal pricing is stable
            assertEq(i * caseChangePointAssets / caseChangePointShares, assets);
        }

        // Verify the withdrawal pricing bonus is within expected bounds
        assertGt(caseChangePointAssets * 100000, caseChangePointShares * 100199);
        assertLt(caseChangePointAssets * 1000, caseChangePointShares * 1002);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        uint256 nextPoint = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT + 1;
        // test next point decreases withdrawal pricing
        assertGt(nextPoint * caseChangePointAssets / caseChangePointShares, ltv.previewRedeem(nextPoint));
    }

    function test_caseSwithPositiveAuctionPointAreaWithdraw() public positiveAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This represents the most precise exchange rate on the stable interval
        // and serves as the baseline for pricing calculations
        uint256 caseChangePointAssets = ltv.previewRedeem(CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT);
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship
        for (uint256 i = caseChangePointAssets - 100; i <= caseChangePointAssets; ++i) {
            uint256 shares = ltv.previewWithdraw(i);

            uint256 roundedUp = (i * caseChangePointShares + (caseChangePointAssets - 1)) / caseChangePointAssets;
            assertEq(roundedUp, shares);
        }

        // Verify the withdrawal pricing bonus is within expected bounds
        assertGt(caseChangePointAssets * 100000, caseChangePointShares * 100199);
        assertLt(caseChangePointAssets * 1000, caseChangePointShares * 1002);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        uint256 nextPoint = caseChangePointAssets + 1;
        // test next point decreases withdrawal pricing
        assertGt(ltv.previewWithdraw(nextPoint), nextPoint * caseChangePointShares / caseChangePointAssets);
    }
}
