// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
import './utils/BaseTest.t.sol';

contract ApproveExtendedTest is BaseTest {
    function test_approve_allowance(address owner, address user) 
        public 
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) 
    {
        vm.stopPrank();
        vm.startPrank(owner);

        assertEq(dummyLTV.allowance(owner, user), 0);

        uint256 approveAmount = 5 * 10 ** 17;
        bool success = dummyLTV.approve(user, approveAmount);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), approveAmount);
    }
    function test_BIGnumbers(address owner, address user) 
        public 
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(owner);

        uint256 maxValue = type(uint256).max;
        
        bool success = dummyLTV.approve(user, maxValue);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), maxValue);

        uint256 bigNumber = 2**200;
        success = dummyLTV.approve(user, bigNumber);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), bigNumber);
    }
    function test_SMALLnumbers(address owner, address user) 
        public 
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) 
    {
        vm.stopPrank();
        vm.startPrank(owner);

        uint256 oneWei = 1;
        bool success = dummyLTV.approve(user, oneWei);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), oneWei);

        uint256 fewWei = 42;
        success = dummyLTV.approve(user, fewWei);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), fewWei);

        uint256 oneGwei = 10**9;
        success = dummyLTV.approve(user, oneGwei);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), oneGwei);
    }
    function test_zero(address owner, address user) 
        public 
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) 
    {
        vm.stopPrank();
        vm.startPrank(owner);

        uint256 initialAmount = 10**18;
        dummyLTV.approve(user, initialAmount);
        assertEq(dummyLTV.allowance(owner, user), initialAmount);
        bool success = dummyLTV.approve(user, 0);
        assertTrue(success);
        assertEq(dummyLTV.allowance(owner, user), 0);
    }
    function test_approve_overwrite(address owner, address user) 
        public 
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) 
    {
        vm.stopPrank();
        vm.startPrank(owner);
        uint256 firstAmount = 10**17;
        dummyLTV.approve(user, firstAmount);
        assertEq(dummyLTV.allowance(owner, user), firstAmount);

        uint256 secondAmount = 5 * 10**17;
        dummyLTV.approve(user, secondAmount);
        assertEq(dummyLTV.allowance(owner, user), secondAmount);

        assertTrue(dummyLTV.allowance(owner, user) != firstAmount);
    }
}