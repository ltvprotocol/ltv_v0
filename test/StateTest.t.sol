// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "utils/BalancedTest.t.sol";
import {ILTV} from "../src/interfaces/ILTV.sol";

contract StateTest is BalancedTest {
    function test_baseTotalSupply(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        // baseTotalSupply is used internally and should match totalSupply initially
        assertEq(dummyLtv.baseTotalSupply(), 10 ** 18);
    }

    function test_borrowToken(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(address(dummyLtv.borrowToken()), address(borrowToken));
    }

    function test_collateralToken(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(address(dummyLtv.collateralToken()), address(collateralToken));
    }

    function test_getLendingConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        // Should initially be the same as lendingConnector
        assertEq(
            address(ILTV(address(dummyLtv)).getLendingConnector()), address(ILTV(address(dummyLtv)).lendingConnector())
        );
    }

    function test_startAuction(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLtv)).startAuction(), dummyLtv.auctionDuration() / 2);
    }
}
