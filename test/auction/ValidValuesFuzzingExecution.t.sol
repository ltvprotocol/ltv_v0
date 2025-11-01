// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DefaultTestData} from "test/utils/BaseTest.t.sol";
import {AuctionTestCommon} from "test/auction/AuctionTestCommon.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";

contract ValidValuesFuzzingExecution is AuctionTestCommon {
    function test_collateralWithdrawAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 3);

        prepareWithdrawAuctionWithCustomCollateralPrice(auctionSize, data.governor, user, 2_111_111_111_111_111_111);
        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        borrowToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureCollateral = int256(uint256(executionSize)) % (-ltv.futureCollateralAssets()) + 1;
        ltv.executeAuctionCollateral(deltaFutureCollateral);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_collateralDepositAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 3);
        prepareDepositAuctionWithCustomCollateralPrice(auctionSize, 2_111_111_111_111_111_111, data.owner);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        deal(address(collateralToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureCollateral =
            -(int256(uint256(executionSize)) % (ltv.futureCollateralAssets() + ltv.futureRewardCollateralAssets())) - 1;
        ltv.executeAuctionCollateral(deltaFutureCollateral);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_borrowWithdrawAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 3);
        vm.assume(user != address(0));

        prepareWithdrawAuctionWithCustomCollateralPrice(auctionSize, data.governor, user, 2_111_111_111_111_111_111);
        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        borrowToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureBorrow =
            int256(uint256(executionSize)) % (-(ltv.futureBorrowAssets() + ltv.futureRewardBorrowAssets())) + 1;
        ltv.executeAuctionBorrow(deltaFutureBorrow);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }

    function test_borrowDepositAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 3);
        vm.assume(user != address(0));
        prepareDepositAuctionWithCustomCollateralPrice(auctionSize, 2_111_111_111_111_111_111, data.owner);

        cacheFutureExecutorInvariantState(ILTV(address(ltv)));

        deal(address(collateralToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureBorrow = -(int256(uint256(executionSize)) % ltv.futureBorrowAssets()) - 1;

        ltv.executeAuctionBorrow(deltaFutureBorrow);

        _checkFutureExecutorInvariantWithCachedState(ILTV(address(ltv)));
    }
}
