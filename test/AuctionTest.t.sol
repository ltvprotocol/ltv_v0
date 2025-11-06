// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "./utils/BalancedTest.t.sol";

contract AuctionTest is BalancedTest {
    function test_executeDepositAuctionBorrow(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        collateralToken.approve(address(dummyLtv), type(uint112).max);
        int256 expectedDeltaCollateral = dummyLtv.previewExecuteAuctionBorrow(-1000);
        int256 deltaCollateral = dummyLtv.executeAuctionBorrow(-1000);

        assertEq(deltaCollateral, -475);
        assertEq(expectedDeltaCollateral, deltaCollateral);
    }

    function test_executeDepositAuctionCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        collateralToken.approve(address(dummyLtv), type(uint112).max);
        int256 expectedDeltaBorrow = dummyLtv.previewExecuteAuctionCollateral(-475);
        int256 deltaBorrow = dummyLtv.executeAuctionCollateral(-475);

        assertEq(deltaBorrow, -1000);
        assertEq(expectedDeltaBorrow, deltaBorrow);
    }

    function test_executeWithdrawAuctionBorrow(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        borrowToken.approve(address(dummyLtv), type(uint112).max);
        int256 deltaCollateral = dummyLtv.executeAuctionBorrow(950);

        assertEq(deltaCollateral, 500);
    }

    function test_executeWithdrawAuctionCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        borrowToken.approve(address(dummyLtv), type(uint112).max);
        int256 expectedDeltaBorrow = dummyLtv.previewExecuteAuctionCollateral(500);
        int256 deltaBorrow = dummyLtv.executeAuctionCollateral(500);

        assertEq(deltaBorrow, 950);
        assertEq(expectedDeltaBorrow, deltaBorrow);
    }
}
