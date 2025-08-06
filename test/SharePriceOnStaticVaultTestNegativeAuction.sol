// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BaseTest.t.sol";

/**
 * @title SharePriceOnStaticVaultTestNegativeAuction
 * @dev This contract tests token pricing behavior for projected deposits and withdrawals
 * in a static vault state with negative auction (negative futureBorrow/futureCollateral and positive auction reward).
 * It focuses on how the vault handles different cases of our math and edge points on case change.
 */
contract SharePriceOnStaticVaultTestNegativeAuction is BaseTest {
    // Point where case changes from cebc to ceccb for negative auction
    uint256 private constant CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT = 3_984_000;

    // Point where the negative pricing penalty becomes zero. At this point penalty from
    // cecb case fully disappears because of payments for cecbc case.
    uint256 private constant ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT = 4_190_000;

    // Number of test iterations to run within a 10-second timeframe
    uint256 private constant TEN_SECONDS_TEST_ITERATION_AMOUNT = 15564;

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
            startAuction: 500,
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
     * This test verifies consistent price calculation for redeems in cmcb case
     */
    function test_caseDynamicNegativeAuctionStableRate() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 assets = ltv.previewRedeem(i);

            // 4% of assets will be taken as fee
            assertEq(assets, i - (i * 4 + 99) / 100);
        }
    }

    function test_caseDynamicNegativeAuctionStableRateWithdraw() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 shares = ltv.previewWithdraw(i);

            // 4.1666666% of assets will be taken as fee
            assertEq(shares, i + ((((i * 41666666) / 10000000) + 99) / 100));
        }
    }

    /**
     * @dev Test makes sure cecb case is working correctly and checking switch to cecbc case.
     * Makes sure that share price starts to decrease after case change point to the 0.961165048
     */
    function test_caseDynamicNegativeAuctionDynamicRate() public negativeAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This point represents the most precise exchange rate on the [0, CASE_CHANGE_POINT] interval
        // and serves as the baseline for smaller deposit pricing
        uint256 caseChangePointShares = ltv.previewDeposit(CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT);
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        uint256 step = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that deposit pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT; i += step) {
            uint256 shares = ltv.previewDeposit(i);

            assertEq(i * caseChangePointShares / caseChangePointAssets, shares);
        }

        // Test that deposit pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;
        uint256 initialAssets = caseChangePointAssets;
        uint256 initialShares = caseChangePointShares;
        for (uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + step; i < 80_000_000; i += step) {
            uint256 shares = ltv.previewDeposit(i);

            // deposit pricing is decreasing each step
            assertGt(i * initialShares, initialAssets * shares);
            initialAssets = i;
            initialShares = shares;
        }

        // Verify bounds for large deposit:
        // - deposit pricing should not drop below 96.5% for 80M shares
        // - Price should approach 96.1165% asymptotically
        assertLt(ltv.previewDeposit(80_000_000), 80_000_000 * 965 / 1000);

        assertGt(ltv.previewDeposit(80_000_000_000_000_000), 80_000_000_000_000_000 * 961_165 / 1_000_000);
        assertLt(ltv.previewDeposit(80_000_000_000_000_000), 80_000_000_000_000_000 * 961_166 / 1_000_000);
    }

    function test_caseDynamicNegativeAuctionDynamicRateMint() public negativeAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This point represents the most precise exchange rate on the [0, CASE_CHANGE_POINT] interval
        // and serves as the baseline for smaller deposit pricing
        uint256 caseChangePointShares = ltv.previewDeposit(CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT);
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        uint256 step = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that deposit pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT; i += step) {
            uint256 newAssets = ltv.previewMint(i);

            uint256 roundedUp = (i * caseChangePointAssets + caseChangePointShares - 1) / caseChangePointShares;
            assertEq(roundedUp, newAssets);
        }

        // Test that deposit pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;
        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + step; i < 80_000_000; i += step) {
            uint256 newAssets = ltv.previewMint(i);

            // mint pricing is increasing each step (need more assets per share)
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGt(newAssets * oldShares, oldAssets * i);

            oldShares = i;
            oldAssets = newAssets;
        }

        // Verify bounds for large deposit:
        // - deposit pricing should not drop below 96.0% for 80M shares
        // - Price should approach 96.1165% asymptotically
        uint256 amount = 80_000_000;
        uint256 assets = ltv.previewMint(amount);

        assertLt(assets, amount * 1_000 / 960);

        uint256 bigAmount = 80_000_000_000_000_000;
        uint256 bigAssets = ltv.previewMint(bigAmount);

        assertGt(bigAssets, bigAmount * 1_000_000 / 961_166);
        assertLt(bigAssets, bigAmount * 1_000_000 / 961_165);
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
    function test_zeroRewardNegativeAuctionPointArea() public negativeAuctionTest {
        uint256 initialShares = ltv.previewDeposit(ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100);
        uint256 initialAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;
        assertGt(initialShares, initialAssets);

        // Test the transition area around the zero reward point
        // Verify that the deposit pricing increases smoothly and never
        // goes above 1:1 before the critical point, ensuring fair treatment
        for (
            uint256 i = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 shares = ltv.previewDeposit(i);
            // test that deposit pricing is decreasing
            assertGe(i * initialShares, initialAssets * shares);
            initialAssets = i;
            initialShares = shares;
            // test that deposit pricing is never less than 1
            assertGe(shares, i);
        }

        // Verify that immediately after the zero reward point,
        // the deposit pricing exceeds 1:1
        uint256 nextPoint = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        assertLt(ltv.previewDeposit(nextPoint), nextPoint);
    }

    function test_zeroRewardNegativeAuctionPointAreaMint() public negativeAuctionTest {
        uint256 zeroRewardPointShares = ltv.previewDeposit(ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT);

        uint256 oldShares = zeroRewardPointShares - 100;
        uint256 oldAssets = ltv.previewMint(oldShares);
        assertGt(oldShares, oldAssets);

        // Test the transition area around the zero reward point
        // Verify that the deposit pricing increases smoothly and never
        // goes above 1:1 before the critical point, ensuring fair treatment
        for (uint256 i = zeroRewardPointShares - 100; i <= zeroRewardPointShares; ++i) {
            uint256 newAssets = ltv.previewMint(i);

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
        // uint256 nextPoint = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        // assertLt(ltv.previewMint(nextPoint), nextPoint);
        uint256 nextPoint = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        assertGt(ltv.previewMint(nextPoint), nextPoint);
    }

    /**
     * @dev Test the case switch from cecb to cecbc. Makes sure that price is stable up to the case change point
     * and then drops immediately after the case change point.
     */
    function test_caseSwithNegativeAuctionPointArea() public negativeAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This represents the most precise exchange rate on the stable interval
        // and serves as the baseline for pricing calculations
        uint256 caseChangePointShares = ltv.previewDeposit(CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT);
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship
        for (
            uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 shares = ltv.previewDeposit(i);
            // test that deposit pricing is stable
            assertEq(i * caseChangePointShares / caseChangePointAssets, shares);
        }

        // Verify the deposit pricing bonus is within expected bounds, less than 0.2058%
        assertGt(caseChangePointShares * 10000, caseChangePointAssets * 1002);
        assertLt(caseChangePointShares * 1000000, caseChangePointAssets * 1002058);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        uint256 nextPoint = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        // test next point decreases withdrawal pricing
        assertGt(nextPoint * caseChangePointAssets / caseChangePointShares, ltv.previewRedeem(nextPoint));
    }

    function test_caseSwithNegativeAuctionPointAreaMint() public negativeAuctionTest {
        // Use the case change point as the reference for stable pricing calculation
        // This represents the most precise exchange rate on the stable interval
        // and serves as the baseline for pricing calculations
        uint256 caseChangePointShares = ltv.previewDeposit(CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT);
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship
        for (
            uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 assets = ltv.previewMint(i);
            // test that deposit pricing is stable
            uint256 roundedUp = (i * caseChangePointAssets + caseChangePointShares - 1) / caseChangePointShares;
            assertEq(roundedUp, assets);
        }

        // Verify the deposit pricing bonus is within expected bounds, less than 0.2058%
        assertGt(caseChangePointShares * 10000, caseChangePointAssets * 1002);
        assertLt(caseChangePointShares * 1000000, caseChangePointAssets * 1002058);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        uint256 nextPoint = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        // test next point decreases withdrawal pricing (need fewer shares to withdraw same assets)
        assertGt(ltv.previewWithdraw(nextPoint), nextPoint * caseChangePointShares / caseChangePointAssets);
    }
}
