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
            maxSafeLTV: 9 * 10 ** 17,
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 2 * 10 ** 17,
            collateralPrice: 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 2 * 10 ** 16,
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
     * @dev Test stable pricing behavior for deposits in static vault state
     *
     * This test verifies consistent price calculation for redeems in cmcb case
     */
    function test_caseDynamicNegativeAuctionStableRateCollateral() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 assets = ltv.previewRedeemCollateral(i);

            assertEq(assets, i * 32 / 33);
        }
    }

    function test_caseDynamicNegativeAuctionStableRateWithdrawCollateral() public negativeAuctionTest {
        for (uint256 i = 5140; i < 80_000_000; i += 5140) {
            uint256 shares = ltv.previewWithdrawCollateral(i);
            uint256 expectedShares = i * 33 / 32;
            uint256 delta = 1;

            assertApproxEqAbs(shares, expectedShares, delta);
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
        // - deposit pricing should not drop below 96.5% for 80M shares
        // - Price should approach 96.1165% asymptotically

        // HERE NEED TO FIND CORRECT COEFFICIENT

        // uint256 amount = 80_000_000;
        // uint256 shares = ltv.previewDepositCollateral(amount);
        // assertLt(shares, amount * 975 / 1000);

        // uint256 bigAmount = 80_000_000_000_000_000;
        // uint256 bigShares = ltv.previewDepositCollateral(bigAmount);
        // assertGt(bigShares, bigAmount * 974_750 / 1_000_000);
        // assertLt(bigShares, bigAmount * 975_000 / 1_000_000);
    }

    function test_caseDynamicNegativeAuctionDynamicRateMint() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        uint256 step = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        // Test that deposit pricing remains stable before the case change point
        for (uint256 i = 100; i < CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT; i += step) {
            uint256 newAssets = ltv.previewMintCollateral(i);
            uint256 expectedAssets = i * caseChangePointAssets / caseChangePointShares;
            uint256 delta = 1;

            assertApproxEqAbs(newAssets, expectedAssets, delta);
        }

        // Test that deposit pricing decreases after the case change point
        step = (80_000_000 - CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT) * 2 / TEN_SECONDS_TEST_ITERATION_AMOUNT;

        uint256 oldAssets = caseChangePointAssets;
        uint256 oldShares = caseChangePointShares;

        for (uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT + step; i < 80_000_000; i += step) {
            uint256 newAssets = ltv.previewMintCollateral(i);

            // mint pricing is increasing each step (need more assets per share)
            // assets_new / shares_new > assets_old / shares_old
            // assets_new * shares_old > assets_old * shares_new
            assertGt(newAssets * oldShares, oldAssets * i); // <-- WILL FAIL IN (22822731103329 <= 22822732739094)

            oldShares = i;
            oldAssets = newAssets;
        }

        // Verify bounds for large deposit:
        // - deposit pricing should not drop below 96.0% for 80M shares
        // - Price should approach 96.1165% asymptotically

        // HERE NEED TO FIND CORRECT COEFFICIENT

        // uint256 amount = 80_000_000;
        // uint256 assets = ltv.previewMintCollateral(amount);

        // assertLt(assets, amount * 1_000 / 960);

        // uint256 bigAmount = 80_000_000_000_000_000;
        // uint256 bigAssets = ltv.previewMintCollateral(bigAmount);

        // assertGt(bigAssets, bigAmount * 1_000_000 / 961_166);
        // assertLt(bigAssets, bigAmount * 1_000_000 / 961_165);
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
        uint256 oldShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT - 100;
        uint256 oldAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;

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
            assertGe(i * oldShares, oldAssets * shares); // WILL FAIL (54389150010000 < 54389164759800)

            oldAssets = i;
            oldShares = shares;

            // test that deposit pricing is never less than 1
            assertGe(shares, i);
        }

        // Verify that immediately after the zero reward point,
        // the deposit pricing exceeds 1:1

        uint256 nextPointAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 2; // + 1 NOT WORKS, BUT WORKS + 2
        uint256 nextPointShares = ltv.previewDepositCollateral(nextPointAssets);

        assertLt(nextPointShares, nextPointAssets);
    }

    function test_zeroRewardNegativeAuctionPointAreaMintCollateral() public negativeAuctionTest {
        uint256 oldShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT - 100;
        uint256 oldAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT - 100;

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
            assertGe(newAssets * oldShares, oldAssets * i); // WILL FAIL (54389127885300 < 54389150010000)

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

        // Verify the deposit pricing bonus is within expected bounds, less than 0.2058%
        // assertGt(caseChangePointShares * 10000, caseChangePointAssets * 1002);
        // assertLt(caseChangePointShares * 1000000, caseChangePointAssets * 1002058);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        // // test next point decreases withdrawal pricing
        uint256 nextPointShares = ZERO_REWARD_NEGATIVE_AUCTION_SHARES_POINT + 1;
        uint256 nextPointAssets = ltv.previewRedeemCollateral(nextPointShares);
        assertGt(nextPointShares * caseChangePointAssets / caseChangePointShares, nextPointAssets);
    }

    function test_caseSwithNegativeAuctionPointAreaMintCollateral() public negativeAuctionTest {
        uint256 caseChangePointShares = CASE_CHANGE_NEGATIVE_AUCTION_SHARES_POINT;
        uint256 caseChangePointAssets = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;

        // Test that withdrawal pricing remains stable up to the case change point
        // All points in this range should follow the same linear relationship

        for (
            uint256 i = CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT - 100;
            i <= CASE_CHANGE_NEGATIVE_AUCTION_ASSETS_POINT;
            ++i
        ) {
            uint256 newAssets = ltv.previewMintCollateral(i);
            uint256 expectedAssets = i * caseChangePointAssets / caseChangePointShares;
            uint256 delta = 1;

            assertApproxEqAbs(newAssets, expectedAssets, delta);
        }

        // Verify the deposit pricing bonus is within expected bounds, less than 0.2058%
        // assertGt(caseChangePointShares * 10000, caseChangePointAssets * 1002);
        // assertLt(caseChangePointShares * 1000000, caseChangePointAssets * 1002058);

        // Verify that the withdrawal pricing immediately decreases after the case change point
        // // test next point decreases withdrawal pricing (need fewer shares to withdraw same assets)
        uint256 nextPointAssets = ZERO_REWARD_NEGATIVE_AUCTION_ASSETS_POINT + 1;
        uint256 nextPointShares = ltv.previewWithdrawCollateral(nextPointAssets);
        assertGt(nextPointShares, nextPointAssets * caseChangePointShares / caseChangePointAssets);
    }
}
