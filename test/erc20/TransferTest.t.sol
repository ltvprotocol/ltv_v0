// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract TransferTest is BaseTest {
    function test_mintTransfer(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= mintAmount);

        ltv.mintFreeTokens(mintAmount, userA);
        assertEq(ltv.balanceOf(userA), mintAmount);

        vm.startPrank(userA);
        bool transferSuccess = ltv.transfer(userB, transferAmount);
        vm.stopPrank();

        assertTrue(transferSuccess);
        assertEq(ltv.balanceOf(userB), transferAmount);
        assertEq(ltv.balanceOf(userA), mintAmount - transferAmount);

        vm.startPrank(userB);
        ltv.approve(defaultData.owner, transferAmount);
        uint256 allowance = ltv.allowance(userB, defaultData.owner);
        vm.stopPrank();

        assertEq(allowance, transferAmount);
    }

    function test_failedTransferBalance(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(transferAmount > 0);

        vm.startPrank(userB);
        vm.expectRevert();
        ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), 0);
        assertEq(ltv.balanceOf(userB), 0);
    }

    function test_zeroTransfer(DefaultTestData memory defaultData, address userA, address userB, uint128 mintAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(mintAmount > 0);

        ltv.mintFreeTokens(mintAmount, userA);

        uint256 initialBalanceA = ltv.balanceOf(userA);
        uint256 initialBalanceB = ltv.balanceOf(userB);

        vm.expectEmit(true, true, false, true);
        emit Transfer(userA, userB, 0);

        vm.startPrank(userA);
        bool zeroTransferSuccess = ltv.transfer(userB, 0);
        vm.stopPrank();

        assertTrue(zeroTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalanceA);
        assertEq(ltv.balanceOf(userB), initialBalanceB);
    }

    function test_selfTransfer(
        DefaultTestData memory defaultData,
        address userA,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= mintAmount);

        ltv.mintFreeTokens(mintAmount, userA);
        uint256 initialBalance = ltv.balanceOf(userA);

        vm.expectEmit(true, true, false, true);
        emit Transfer(userA, userA, transferAmount);

        vm.startPrank(userA);
        bool selfTransferSuccess = ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertTrue(selfTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalance);
    }

    function test_transferToZeroAddress(
        DefaultTestData memory defaultData,
        address userA,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= mintAmount);

        ltv.mintFreeTokens(mintAmount, userA);

        uint256 initialZeroBalance = ltv.balanceOf(address(0));

        vm.expectEmit(true, true, false, true);
        emit Transfer(userA, address(0), transferAmount);

        vm.startPrank(userA);
        bool transferResult = ltv.transfer(address(0), transferAmount);
        vm.stopPrank();

        assertTrue(transferResult);
        assertEq(ltv.balanceOf(userA), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(address(0)), initialZeroBalance + transferAmount);
    }

    function testFuzz_transferWithEvents(
        DefaultTestData memory defaultData,
        address user,
        address recipient,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(recipient != address(0));
        vm.assume(user != recipient);
        vm.assume(user != defaultData.owner);
        vm.assume(recipient != defaultData.owner);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= mintAmount);

        ltv.mintFreeTokens(mintAmount, user);

        vm.expectEmit(true, true, false, true);
        emit Transfer(user, recipient, transferAmount);

        vm.startPrank(user);
        bool success = ltv.transfer(recipient, transferAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.balanceOf(user), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
    }

    function testFuzz_approveWithEvents(
        DefaultTestData memory defaultData,
        address user,
        address spender,
        uint128 mintAmount,
        uint128 approveAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(spender != address(0));
        vm.assume(user != spender);
        vm.assume(user != defaultData.owner);
        vm.assume(spender != defaultData.owner);
        vm.assume(mintAmount > 0);

        ltv.mintFreeTokens(mintAmount, user);

        vm.expectEmit(true, true, false, true);
        emit Approval(user, spender, approveAmount);

        vm.startPrank(user);
        bool success = ltv.approve(spender, approveAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.allowance(user, spender), approveAmount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
