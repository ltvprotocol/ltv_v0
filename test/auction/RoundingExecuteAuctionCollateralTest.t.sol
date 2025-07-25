// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionTestCommon, DefaultTestData, Constants} from "./AuctionTestCommon.t.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";
import {ILTV} from "../../src/interfaces/ILTV.sol";

contract RoundingExecuteAuctionCollateralTest is AuctionTestCommon {
    function test_executeAuctionCollateralWithdrawAuctionRounding2Up(
        DefaultTestData memory data,
        address user,
        uint112 amount,
        uint112 executionAmount
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(user != data.feeCollector);
        vm.assume(amount >= 2);
        prepareWithdrawAuction(amount, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        int256 futureCollateralBefore = ltv.futureCollateralAssets();

        executionAmount = executionAmount % (amount / 2) + 1;

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);

        borrowToken.approve(address(ltv), type(uint256).max);
        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(int256(uint256(executionAmount)));

        int256 futureCollateralAfter = ltv.futureCollateralAssets();

        assertEq(futureCollateralAfter, futureCollateralBefore + int256(uint256(executionAmount)));

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_executeAuctionCollateralWithdrawAuctionRounding3Up(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareWithdrawAuction(2000000, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        ltv.setFutureBorrowAssets(-2010000);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);

        borrowToken.approve(address(ltv), type(uint256).max);
        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(2222);

        int256 expectedDeltaFutureBorrow = 4467;
        int256 futureBorrowAfter = ltv.futureBorrowAssets();
        assertTrue(futureBorrowAfter == futureBorrowBefore + expectedDeltaFutureBorrow || futureBorrowAfter == 0);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_executeAuctionCollateralWithdrawAuctionRounding5Up(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareWithdrawAuction(2000000, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        int256 initialFutureRewardBorrow = ltv.futureRewardBorrowAssets();

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(2222);

        assertEq(ltv.futureRewardBorrowAssets(), initialFutureRewardBorrow - 44);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_executeAuctionCollateralWithdrawAuctionRounding7Up(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareWithdrawAuction(2000000, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        vm.startPrank(user);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();

        deal(address(borrowToken), user, type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(2222);
        int256 expectedDeltaFutureBorrow = 4444;

        assertEq(ltv.futureBorrowAssets(), futureBorrowBefore + expectedDeltaFutureBorrow);
        assertEq(type(uint256).max, borrowToken.balanceOf(user) - 11 + uint256(expectedDeltaFutureBorrow));

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_executeAuctionCollateralDepositAuctionRounding2Up(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareDepositAuction(2000000, data.owner);

        vm.roll(ltv.startAuction() + 243);

        int256 futureCollateralBefore = ltv.futureCollateralAssets();

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint256).max);
        collateralToken.approve(address(ltv), type(uint256).max);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(-2222);

        int256 futureCollateralAfter = ltv.futureCollateralAssets();

        assertEq(futureCollateralAfter, futureCollateralBefore - 2227);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_executeAuctionCollateralDepositAuctionRounding3Up(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareDepositAuction(2000000, data.owner);

        vm.roll(ltv.startAuction() + 243);

        ltv.setFutureBorrowAssets(2010000);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();
        int256 futureCollateralBefore = ltv.futureCollateralAssets();
        int256 expectedDeltaFutureCollateral = -2227;

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint256).max);
        collateralToken.approve(address(ltv), type(uint256).max);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        ltv.executeAuctionCollateral(-2222);

        assertEq(futureCollateralBefore + expectedDeltaFutureCollateral, ltv.futureCollateralAssets());
        assertEq(futureBorrowBefore - 4476, ltv.futureBorrowAssets());

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    // no test since no borrow reward for deposit auction
    function test_executeAuctionCollateralDepositAuctionRounding5Up() public {}

    // no test since no borrow reward for deposit auction
    function test_executeAuctionCollateralDepositAuctionRounding7Up() public {}
}
