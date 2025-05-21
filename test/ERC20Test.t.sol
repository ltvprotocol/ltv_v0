// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
import './utils/BaseTest.t.sol';

contract ERC20Test is BaseTest {
    function test_totalSupply(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLTV.totalSupply(), 10 ** 18 + 100);
    }

    function test_transferFrom(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.approve(user, 10 ** 17);
        vm.startPrank(user);
        dummyLTV.transferFrom(owner, user, 10 ** 17);
        assertEq(dummyLTV.balanceOf(user), 10 ** 17);
    }

    function test_decimals(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLTV.decimals(), 18);
    }

    function test_name(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLTV.name(), 'Dummy LTV');
    }

    function test_symbol(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLTV.symbol(), 'DLTV');
    }

    function test_approve(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);

        bool success = dummyLTV.approve(user, 10 ** 18);

        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), 10 ** 18);
    }
}
