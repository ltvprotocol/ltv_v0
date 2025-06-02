// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract ApproveTest is BaseTest {
    function test_approveAllowance(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);

        address owner = defaultData.owner;

        vm.startPrank(owner);

        assertEq(ltv.allowance(owner, user), 0);

        uint256 approveAmount = 5 * 10 ** 17;
        bool success = ltv.approve(user, approveAmount);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), approveAmount);
    }

    function test_bigNumbers(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);

        address owner = defaultData.owner;

        vm.startPrank(owner);

        uint256 maxValue = type(uint256).max;

        bool success = ltv.approve(user, maxValue);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), maxValue);

        uint256 bigNumber = 2 ** 200;
        success = ltv.approve(user, bigNumber);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), bigNumber);
    }

    function test_smallNumbers(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);

        address owner = defaultData.owner;

        vm.startPrank(owner);

        uint256 oneWei = 1;
        bool success = ltv.approve(user, oneWei);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), oneWei);

        uint256 fewWei = 42;
        success = ltv.approve(user, fewWei);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), fewWei);

        uint256 oneGwei = 10 ** 9;
        success = ltv.approve(user, oneGwei);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), oneGwei);
    }

    function test_zero(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);

        address owner = defaultData.owner;

        vm.startPrank(owner);

        uint256 initialAmount = 10 ** 18;
        ltv.approve(user, initialAmount);
        assertEq(ltv.allowance(owner, user), initialAmount);

        bool success = ltv.approve(user, 0);
        assertTrue(success);
        assertEq(ltv.allowance(owner, user), 0);
    }

    function test_approveOverwrite(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);

        address owner = defaultData.owner;

        vm.startPrank(owner);

        uint256 firstAmount = 10 ** 17;
        ltv.approve(user, firstAmount);
        assertEq(ltv.allowance(owner, user), firstAmount);

        uint256 secondAmount = 5 * 10 ** 17;
        ltv.approve(user, secondAmount);
        assertEq(ltv.allowance(owner, user), secondAmount);

        assertTrue(ltv.allowance(owner, user) != firstAmount);
    }
}
