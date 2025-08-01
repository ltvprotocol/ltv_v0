// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionTestCommon, DefaultTestData} from "./AuctionTestCommon.t.sol";

contract AuctionCertainNumbersTest is AuctionTestCommon {
    struct AuctionCertainNumbersTestData {
        int256 futureBorrowAssets;
        int256 futureCollateralAssets;
        int256 futureRewardBorrowAssets;
        int256 futureRewardCollateralAssets;
        int256 userBorrowAssets;
        int256 userCollateralAssets;
        int256 feeCollectorBorrowAssets;
        int256 feeCollectorCollateralAssets;
        uint256 totalAssets;
    }

    function getAuctionCertainNumbersTestData(address user, address feeCollector)
        public
        view
        returns (AuctionCertainNumbersTestData memory)
    {
        return AuctionCertainNumbersTestData({
            futureBorrowAssets: ltv.futureBorrowAssets(),
            futureCollateralAssets: ltv.futureCollateralAssets(),
            futureRewardBorrowAssets: ltv.futureRewardBorrowAssets(),
            futureRewardCollateralAssets: ltv.futureRewardCollateralAssets(),
            userBorrowAssets: int256(borrowToken.balanceOf(user)),
            userCollateralAssets: int256(collateralToken.balanceOf(user)),
            feeCollectorBorrowAssets: int256(borrowToken.balanceOf(feeCollector)),
            feeCollectorCollateralAssets: int256(collateralToken.balanceOf(feeCollector)),
            totalAssets: ltv.totalAssets()
        });
    }

    function test_executeWithdrawAuctionBorrowCertainNumbers(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareWithdrawAuctionWithCustomCollateralPrice(2000000, data.governor, user, 2_111_111_111_111_111_111);
        // making rounding unprecice
        ltv.setFutureCollateralAssets(ltv.futureCollateralAssets() - 7);

        vm.roll(ltv.startAuction() + 243);

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint128).max);
        borrowToken.approve(address(ltv), type(uint128).max);

        AuctionCertainNumbersTestData memory initialState = getAuctionCertainNumbersTestData(user, data.feeCollector);
        ltv.executeAuctionBorrow(10001);
        AuctionCertainNumbersTestData memory finalState = getAuctionCertainNumbersTestData(user, data.feeCollector);

        // check how much borrow tokens user provided
        assertEq(initialState.userBorrowAssets - 10001, finalState.userBorrowAssets);

        // check how much collateral tokens user received
        assertEq(initialState.userCollateralAssets + 4748, finalState.userCollateralAssets);

        // check fee collector rewards
        assertEq(initialState.feeCollectorBorrowAssets + 76, finalState.feeCollectorBorrowAssets);
        assertEq(initialState.feeCollectorCollateralAssets, finalState.feeCollectorCollateralAssets);

        // check future rewards changed as expected
        assertEq(initialState.futureRewardBorrowAssets - 100, finalState.futureRewardBorrowAssets);
        assertEq(initialState.futureRewardCollateralAssets, finalState.futureRewardCollateralAssets);

        // check future borrow change
        assertEq(initialState.futureBorrowAssets + 10001 + 24, finalState.futureBorrowAssets);

        // check future collateral change
        assertEq(initialState.futureCollateralAssets + 4748, finalState.futureCollateralAssets);

        // check future rewards are proportional
        assertEq(initialState.futureRewardBorrowAssets * 10001 / initialState.futureBorrowAssets, -100);

        // check total assets didn't change
        assertApproxEqAbs(finalState.totalAssets, initialState.totalAssets, 1);
    }

    function test_executeWithdrawAuctionCollateralCertainNumbers(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareWithdrawAuctionWithCustomCollateralPrice(2000000, data.governor, user, 2_111_111_111_111_111_111);
        // making rounding unprecice
        ltv.setFutureCollateralAssets(ltv.futureCollateralAssets() - 7);

        vm.roll(ltv.startAuction() + 243);

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint128).max);
        borrowToken.approve(address(ltv), type(uint128).max);

        AuctionCertainNumbersTestData memory initialState = getAuctionCertainNumbersTestData(user, data.feeCollector);
        ltv.executeAuctionCollateral(4748);
        AuctionCertainNumbersTestData memory finalState = getAuctionCertainNumbersTestData(user, data.feeCollector);

        // check how much borrow tokens user provided
        assertEq(initialState.userBorrowAssets - 9999, finalState.userBorrowAssets);

        // check how much collateral tokens user received
        assertEq(initialState.userCollateralAssets + 4748, finalState.userCollateralAssets);

        // check fee collector rewards
        assertEq(initialState.feeCollectorBorrowAssets + 75, finalState.feeCollectorBorrowAssets);
        assertEq(initialState.feeCollectorCollateralAssets, finalState.feeCollectorCollateralAssets);

        // check future rewards changed as expected
        assertEq(initialState.futureRewardBorrowAssets - 100, finalState.futureRewardBorrowAssets);
        assertEq(initialState.futureRewardCollateralAssets, finalState.futureRewardCollateralAssets);

        // check future borrow change
        assertEq(initialState.futureBorrowAssets + 9999 + 25, finalState.futureBorrowAssets);

        // check future collateral change
        assertEq(initialState.futureCollateralAssets + 4748, finalState.futureCollateralAssets);

        // check future rewards are proportional
        assertEq(initialState.futureRewardBorrowAssets * 10001 / initialState.futureBorrowAssets, -100);

        // check total assets didn't change
        assertApproxEqAbs(finalState.totalAssets, initialState.totalAssets, 1);
    }

    function test_executeDepositAuctionBorrowCertainNumbers(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareDepositAuctionWithCustomCollateralPrice(2000000, 2_111_111_111_111_111_111, data.owner);
        // making rounding unprecice
        ltv.setFutureCollateralAssets(ltv.futureCollateralAssets() - 7);

        vm.roll(ltv.startAuction() + 243);

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint128).max);
        collateralToken.approve(address(ltv), type(uint128).max);

        AuctionCertainNumbersTestData memory initialState = getAuctionCertainNumbersTestData(user, data.feeCollector);
        ltv.executeAuctionBorrow(-10000);
        AuctionCertainNumbersTestData memory finalState = getAuctionCertainNumbersTestData(user, data.feeCollector);

        // check how much borrow tokens user received
        assertEq(initialState.userBorrowAssets + 10000, finalState.userBorrowAssets);

        // check how much collateral tokens user provided
        assertEq(initialState.userCollateralAssets - 4725, finalState.userCollateralAssets);

        // check fee collector rewards
        assertEq(initialState.feeCollectorBorrowAssets, finalState.feeCollectorBorrowAssets);
        assertEq(initialState.feeCollectorCollateralAssets + 35, finalState.feeCollectorCollateralAssets);

        // check future rewards changed as expected
        assertEq(initialState.futureRewardBorrowAssets, finalState.futureRewardBorrowAssets);
        assertEq(initialState.futureRewardCollateralAssets + 47, finalState.futureRewardCollateralAssets);

        // check future borrow change
        assertEq(initialState.futureBorrowAssets - 10000, finalState.futureBorrowAssets);

        // check future collateral change
        assertEq(initialState.futureCollateralAssets - 4725 - 12, finalState.futureCollateralAssets);

        // check future rewards are proportional
        assertEq(initialState.futureRewardCollateralAssets * 4737 / initialState.futureCollateralAssets, -47);

        // check total assets didn't change
        assertApproxEqAbs(finalState.totalAssets, initialState.totalAssets, 1);
    }

    function test_executeDepositAuctionCollateralCertainNumbers(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareDepositAuctionWithCustomCollateralPrice(2000000, 2_111_111_111_111_111_111, data.owner);
        // making rounding unprecice
        ltv.setFutureCollateralAssets(ltv.futureCollateralAssets() - 7);

        vm.roll(ltv.startAuction() + 243);

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint128).max);
        collateralToken.approve(address(ltv), type(uint128).max);

        AuctionCertainNumbersTestData memory initialState = getAuctionCertainNumbersTestData(user, data.feeCollector);
        ltv.executeAuctionCollateral(-4726);
        AuctionCertainNumbersTestData memory finalState = getAuctionCertainNumbersTestData(user, data.feeCollector);

        // check how much borrow tokens user received
        assertEq(initialState.userBorrowAssets + 10000, finalState.userBorrowAssets);

        // check how much collateral tokens user provided
        assertEq(initialState.userCollateralAssets - 4726, finalState.userCollateralAssets);

        // check fee collector rewards
        assertEq(initialState.feeCollectorBorrowAssets, finalState.feeCollectorBorrowAssets);
        assertEq(initialState.feeCollectorCollateralAssets + 36, finalState.feeCollectorCollateralAssets);

        // check future rewards changed as expected
        assertEq(initialState.futureRewardBorrowAssets, finalState.futureRewardBorrowAssets);
        assertEq(initialState.futureRewardCollateralAssets + 47, finalState.futureRewardCollateralAssets);

        // check future borrow change
        assertEq(initialState.futureBorrowAssets - 10000, finalState.futureBorrowAssets);

        // check future collateral change
        assertEq(initialState.futureCollateralAssets - 4726 - 11, finalState.futureCollateralAssets);

        // check future rewards are proportional
        assertEq(initialState.futureRewardCollateralAssets * 4737 / initialState.futureCollateralAssets, -47);

        // check total assets didn't change
        assertApproxEqAbs(finalState.totalAssets, initialState.totalAssets, 1);
    }
}
