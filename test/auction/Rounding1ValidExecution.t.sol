// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionTestCommon, DefaultTestData, Constants} from "./AuctionTestCommon.t.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";

contract RoundingExecuteAuctionBorrowTest is AuctionTestCommon {
    function test_executeAuctionBorrowWithdrawAuctionRounding1Down(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareWithdrawAuction(2000000, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();
        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);
        AuctionState memory initialAuctionState = getAuctionState();
        ltv.executeAuctionBorrow(4444);
        int256 futureBorrowAfter = ltv.futureBorrowAssets();
        assertEq(futureBorrowAfter, futureBorrowBefore + 4454);
        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_executeAuctionBorrowWithdrawAuctionRounding4Down(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareWithdrawAuction(2000000, data.governor, user);

        vm.roll(ltv.startAuction() + 243);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();
        int256 futureCollateralBefore = ltv.futureCollateralAssets();

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);
        AuctionState memory initialAuctionState = getAuctionState();
        ltv.executeAuctionBorrow(4443);
        int256 expectedDeltaFutureBorrow = 4453;
        int256 futureBorrowAfter = ltv.futureBorrowAssets();
        int256 futureCollateralAfter = ltv.futureCollateralAssets();
        assertEq(futureBorrowAfter, futureBorrowBefore + expectedDeltaFutureBorrow);
        assertEq(futureCollateralAfter, futureCollateralBefore + 2226);

        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_executeAuctionBorrowWithdrawAuctionRounding6Down() public {
        // no future reward collateral for withdraw auction
    }

    function test_executeAuctionBorrowWithdrawAuctionRounding8Down() public {
        // no future reward collateral for withdraw auction
    }

    function test_executeAuctionBorrowDepositAuctionRounding1Down(
        DefaultTestData memory data,
        address user,
        // uint112 because of overflow. futureBorrowAssets * deltaRealBorrowAssets * 1000(auction length) overflows uint256 if uint128 is used
        uint112 amount,
        uint112 executionAmount
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(amount >= 2);
        executionAmount = executionAmount % amount + 1;
        prepareDepositAuction(amount);

        vm.roll(ltv.startAuction() + 243);

        int256 futureBorrowBefore = ltv.futureBorrowAssets();

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint256).max);
        collateralToken.approve(address(ltv), type(uint256).max);

        AuctionState memory initialAuctionState = getAuctionState();

        ltv.executeAuctionBorrow(-int256(uint256(executionAmount)));

        int256 futureBorrowAfter = ltv.futureBorrowAssets();

        // no rounding here, deltaFutureBorrow has to be equal to deltaRealBorrow
        assertEq(futureBorrowAfter, futureBorrowBefore - int256(uint256(executionAmount)));

        checkFutureExecutorProfit(initialAuctionState);
    }

    function test_executeAuctionBorrowDepositAuctionRounding4Down(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareDepositAuction(2000000);

        vm.roll(ltv.startAuction() + 243);

        int256 futureCollateralBefore = ltv.futureCollateralAssets();

        vm.startPrank(user);
        deal(address(borrowToken), user, type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);
        AuctionState memory initialAuctionState = getAuctionState();
        ltv.executeAuctionBorrow(-4443);
        int256 futureCollateralAfter = ltv.futureCollateralAssets();
        assertEq(futureCollateralAfter, futureCollateralBefore + 2221);

        checkFutureExecutorProfit(initialAuctionState);
    }
}
