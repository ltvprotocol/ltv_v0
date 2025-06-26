// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./AuctionTestCommon.t.sol";

contract ValidValuesFuzzingExecution is AuctionTestCommon {
    function test_collateralWithdrawAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 2);

        prepareWithdrawAuction(auctionSize, data.governor, user);
        AuctionState memory initialAuctionState = getAuctionState();

        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        borrowToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureCollateral = int256(uint256(executionSize)) % (-ltv.futureCollateralAssets()) + 1;
        ltv.executeAuctionCollateral(deltaFutureCollateral);

        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_collateralDepositAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 2);
        prepareDepositAuction(auctionSize);

        AuctionState memory initialAuctionState = getAuctionState();

        deal(address(collateralToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureCollateral =
            -(int256(uint256(executionSize)) % (ltv.futureCollateralAssets() + ltv.futureRewardCollateralAssets())) - 1;
        ltv.executeAuctionCollateral(deltaFutureCollateral);

        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_borrowWithdrawAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 2);

        prepareWithdrawAuction(auctionSize, data.governor, user);
        AuctionState memory initialAuctionState = getAuctionState();

        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        borrowToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureBorrow =
            int256(uint256(executionSize)) % (-(ltv.futureBorrowAssets() + ltv.futureRewardBorrowAssets())) + 1;
        ltv.executeAuctionBorrow(deltaFutureBorrow);

        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_borrowdDepositAuction(
        DefaultTestData memory data,
        address user,
        uint120 auctionSize,
        uint128 executionSize
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(auctionSize >= 2);
        prepareDepositAuction(auctionSize);

        AuctionState memory initialAuctionState = getAuctionState();

        deal(address(collateralToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        int256 deltaFutureBorrow = -(int256(uint256(executionSize)) % ltv.futureBorrowAssets()) - 1;
        ltv.executeAuctionBorrow(deltaFutureBorrow);

        checkFutureExecutorProfit(initialAuctionState);
    }
}
