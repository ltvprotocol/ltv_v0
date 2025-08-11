// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BaseTest.t.sol";

/**
 * @title SharePriceOnStaticVaultTestPositiveAuctionCollateral
 * @dev This contract tests token pricing behavior for projected deposits and withdrawals collateral
 * tokens in a static vault state. It focuses on how the vault handles different cases of our math and
 * edge points on case change.
 */
contract SharePriceOnStaticVaultTestPositiveAuctionCollateral is BaseTest {
    uint256 constant CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT = 5_150_000;
    uint256 constant ZERO_REWARD_POSITIVE_AUCTION_ASSETS_POINT = 7_550_000;
    uint256 constant CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT = 5_075_000;
    uint256 constant ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT = 7_550_000;

    // Number of test iterations to run within a 10-second timeframe
    uint256 constant TEN_SECONDS_TEST_ITERATION_AMOUNT = 15564;

    modifier positiveAuctionTest() {
        BaseTestInit memory initData = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 15_000_000,
            futureCollateral: 15_000_000,
            auctionReward: -150_000,
            startAuction: 500,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 981_150_000,
            borrowAssets: 732_000_000,
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
            zeroAddressTokens: 981_150_000 + 15_000_000 - 732_000_000 - 15_000_000 - 150_000
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
     * @dev Test stable pricing behavior for deposits collateral in static vault state
     *
     * This test verifies consistent price calculation for deposits collateral in cmbc case
     */
    function test_caseDynamicPositiveAuctionStableRateCollateral() public positiveAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 shares = ltv.previewDepositCollateral(i);
            uint256 expectedShares = i * 100 / 103;

            assertEq(shares, expectedShares);
        }
    }

    /**
     * @dev Test stable pricing behavior for mint collateral in static vault state
     *
     * This test verifies consistent price calculation for mint collateral in cmbc case
     */
    function test_caseDynamicPositiveAuctionStableRateMintCollateral() public positiveAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 assets = ltv.previewMintCollateral(i);
            uint256 expectedAssets = (i * 103 + 99) / 100;

            assertEq(assets, expectedAssets);
        }
    }

    /**
     * @dev Test makes sure cebc case is working correctly and checking switch to ceccb case.
     * Makes sure that share price starts to decrease after case change point to the 0.958333
     */
    function test_caseDynamicPositiveAuctionDynamicRateCollateral() public positiveAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = ltv.previewRedeemCollateral(caseChangePointShares);

        uint256 step = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that withdrawal pricing remains stable before the case change point
        for (uint256 i = 100; i <= CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT; i += step) {
            uint256 newAssets = ltv.previewRedeemCollateral(i);

            assertEq(i * caseChangePointAssets / caseChangePointShares, newAssets);
        }

        // Test that withdrawal pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT + step; i < 80_000_000; i += step) {
            uint256 newAssets = ltv.previewRedeemCollateral(i);

            // withdrawal pricing is decreasing each step
            assertLt(newAssets * oldShares, oldAssets * i);

            oldAssets = newAssets;
            oldShares = i;
        }

        // Verify bounds for large withdrawals:
        // - Withdrawal pricing should not drop below 96.9% for 80M shares
        // - Price should approach 96.969696...% asymptotically

        uint256 amount = 80_000_000;
        uint256 assets = ltv.previewRedeemCollateral(amount);
        assertLt(assets, amount * 98 / 100);

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigAssets = ltv.previewRedeemCollateral(bigAmount);
        assertGt(bigAssets, bigAmount * 9_696_969 / 10_000_000);
        assertLt(bigAssets, bigAmount * 9_696_970 / 10_000_000);
    }

    /**
     * @dev Test makes sure cebc case is working correctly and checking switch to ceccb case.
     * Makes sure that share price starts to decrease after case change point to the 0.958333
     */
    function test_caseDynamicPositiveAuctionDynamicRateWithdrawCollateral() public positiveAuctionTest {
        uint256 caseChangePointAssets = CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT;
        uint256 caseChangePointShares = ltv.previewWithdrawCollateral(caseChangePointAssets);

        uint256 step = caseChangePointAssets * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that withdrawal pricing remains stable before the case change point
        for (uint256 i = 100; i <= caseChangePointAssets; i += step) {
            uint256 newShares = ltv.previewWithdrawCollateral(i);
            uint256 expectedShares = (i * caseChangePointShares + caseChangePointAssets - 1) / caseChangePointAssets;

            assertGe(newShares, expectedShares);
        }

        // Test that withdrawal pricing decreases after the case change point
        step = (80_000_000 - caseChangePointAssets) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = caseChangePointAssets + step; i < 80_000_000; i += step) {
            uint256 newShares = ltv.previewWithdrawCollateral(i);

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
        uint256 shares = ltv.previewWithdrawCollateral(amount);
        assertLt(shares, amount * 33 / 32);

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigShares = ltv.previewWithdrawCollateral(bigAmount);
        assertGt(bigShares, bigAmount * 330 / 321);
        assertLt(bigShares, bigAmount * 33 / 32);
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
    function test_zeroRewardPositiveAuctionPointAreaCollateral() public positiveAuctionTest {
        uint256 oldShares = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT - 100;
        uint256 oldAssets = ltv.previewRedeemCollateral(oldShares);

        // Test the transition area around the zero reward point
        // Verify that the withdrawal pricing decreases smoothly and never
        // goes below 1:1 before the critical point, ensuring fair treatment

        for (
            uint256 i = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT - 100;
            i <= ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 assets = ltv.previewRedeemCollateral(i);
            // test that withdrawal pricing is decreasing

            // assets_new / shares_new < assets_old / shares_old
            // assets_new * shares_old < assets_old * shares_new
            assertLe(assets * oldShares, oldAssets * i);
            oldAssets = assets;
            oldShares = i;

            // test that withdrawal pricing is never less than 1
            assertGe(assets, i);
        }

        // Verify that immediately after the zero reward point,
        // the withdrawal pricing drops below 1:1
        uint256 nextPointShares = ZERO_REWARD_POSITIVE_AUCTION_SHARES_POINT + 1;
        uint256 nextPointAssets = ltv.previewRedeemCollateral(nextPointShares);

        assertLt(nextPointAssets, nextPointShares);
    }

    function test_zeroRewardPositiveAuctionPointAreaWithdrawCollateral() public positiveAuctionTest {
        uint256 oldAssets = ZERO_REWARD_POSITIVE_AUCTION_ASSETS_POINT - 100;
        uint256 oldShares = ltv.previewWithdrawCollateral(oldAssets);

        // Test the transition area around the zero reward point
        // Verify that the withdrawal pricing decreases smoothly and never
        // goes below 1:1 before the critical point, ensuring fair treatment

        for (
            uint256 i = ZERO_REWARD_POSITIVE_AUCTION_ASSETS_POINT - 100;
            i <= ZERO_REWARD_POSITIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 newShares = ltv.previewWithdrawCollateral(i);
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

        uint256 nextPointAssets = ZERO_REWARD_POSITIVE_AUCTION_ASSETS_POINT + 1;
        uint256 nextPointShares = ltv.previewWithdrawCollateral(nextPointAssets);

        assertLt(nextPointAssets, nextPointShares);
    }

    /**
     * @dev Test the case switch from cebc to ceccb. Makes sure that price is stable up to the case change point
     * and then drops immediately after the case change point.
     */
    function test_caseSwithPositiveAuctionPointAreaCollateral() public positiveAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship

        for (
            uint256 i = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT - 100;
            i <= CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT;
            ++i
        ) {
            uint256 newAssets = ltv.previewRedeemCollateral(i);
            uint256 expectedAssets = i * caseChangePointAssets / caseChangePointShares;

            assertLe(newAssets, expectedAssets);
        }

        assertEq(
            ltv.previewRedeemCollateral(CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT),
            CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT
        );

        uint256 nextPointShares = CASE_CHANGE_POSITIVE_AUCTION_SHARES_POINT + 1;
        uint256 nextPointAssets = ltv.previewRedeemCollateral(nextPointShares);
        assertGt(nextPointShares * caseChangePointAssets, nextPointAssets * caseChangePointShares);
    }

    function test_caseSwithPositiveAuctionPointAreaWithdrawCollateral() public positiveAuctionTest {
        uint256 caseChangePointAssets = CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT;
        uint256 caseChangePointShares = ltv.previewWithdrawCollateral(caseChangePointAssets);

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship

        for (uint256 i = caseChangePointAssets - 100; i <= caseChangePointAssets; ++i) {
            uint256 newShares = ltv.previewWithdrawCollateral(i);
            uint256 expectedShares = (i * caseChangePointShares + caseChangePointAssets - 1) / caseChangePointAssets;

            assertEq(newShares, expectedShares);
        }

        uint256 nextPointAssets = CASE_CHANGE_POSITIVE_AUCTION_ASSETS_POINT + 1;
        uint256 nextPointShares = ltv.previewWithdrawCollateral(nextPointAssets);
        assertGt(nextPointShares, nextPointAssets * caseChangePointShares / caseChangePointAssets);
    }
}
