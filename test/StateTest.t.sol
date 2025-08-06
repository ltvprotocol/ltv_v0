// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BalancedTest.t.sol";

contract StateTest is BalancedTest {
    function test_baseTotalSupply(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        // baseTotalSupply is used internally and should match totalSupply initially
        assertEq(dummyLTV.baseTotalSupply(), 10 ** 18);
    }

    function test_borrowToken(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(address(dummyLTV.borrowToken()), address(borrowToken));
    }

    function test_collateralToken(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(address(dummyLTV.collateralToken()), address(collateralToken));
    }

    function test_getLendingConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        // Should initially be the same as lendingConnector
        assertEq(
            address(ILTV(address(dummyLTV)).getLendingConnector()), address(ILTV(address(dummyLTV)).lendingConnector())
        );
    }

    function test_startAuction(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLTV)).startAuction(), dummyLTV.auctionDuration() / 2);
    }
}
