// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract TransferTest is BaseTest {
    function test_mintTransfer(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);

        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 500 * 10 ** 18;

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        uint256 userABalance = ltv.balanceOf(userA);
        assertEq(userABalance, mintAmount);

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

    function test_mintAndFailedTransfer(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);

        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), mintAmount);
        assertEq(ltv.balanceOf(userB), 0);

        vm.startPrank(userB);
        try ltv.transfer(userA, 100 * 10 ** 18) returns (bool success) {
            assertFalse(success);
        } catch {}
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), mintAmount);
        assertEq(ltv.balanceOf(userB), 0);
    }

    function test_zeroTransfer(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);

        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        uint256 initialBalanceA = ltv.balanceOf(userA);
        uint256 initialBalanceB = ltv.balanceOf(userB);

        vm.startPrank(userA);
        bool zeroTransferSuccess = ltv.transfer(userB, 0);
        vm.stopPrank();

        assertTrue(zeroTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalanceA);
        assertEq(ltv.balanceOf(userB), initialBalanceB);
    }

    function test_selfTransfer(DefaultTestData memory defaultData, address userA)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);

        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 300 * 10 ** 18;

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        uint256 initialBalance = ltv.balanceOf(userA);

        vm.startPrank(userA);
        bool selfTransferSuccess = ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertTrue(selfTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalance);
    }

    function test_transferToZeroAddress(DefaultTestData memory defaultData, address userA)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);

        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 100 * 10 ** 18;

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        uint256 initialBalance = ltv.balanceOf(userA);
        uint256 initialZeroBalance = ltv.balanceOf(address(0));

        vm.startPrank(userA);
        bool transferResult = ltv.transfer(address(0), transferAmount);
        vm.stopPrank();

        if (transferResult) {
            assertEq(ltv.balanceOf(userA), initialBalance - transferAmount);
            assertEq(ltv.balanceOf(address(0)), initialZeroBalance + transferAmount);
        } else {
            assertEq(ltv.balanceOf(userA), initialBalance);
            assertEq(ltv.balanceOf(address(0)), initialZeroBalance);
        }
    }

    function testFuzz_mintAndTransfer(
        DefaultTestData memory defaultData,
        address user,
        address recipient,
        uint256 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(recipient != address(0));
        vm.assume(user != recipient);
        vm.assume(user != defaultData.owner);
        vm.assume(recipient != defaultData.owner);
        vm.assume(mintAmount > 0 && mintAmount <= type(uint128).max);
        vm.assume(transferAmount <= mintAmount);

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, user);
        vm.stopPrank();

        assertEq(ltv.balanceOf(user), mintAmount);

        vm.startPrank(user);
        bool success = ltv.transfer(recipient, transferAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.balanceOf(user), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
    }

    function testFuzz_approveAmounts(
        DefaultTestData memory defaultData,
        address user,
        address spender,
        uint256 mintAmount,
        uint256 approveAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(spender != address(0));
        vm.assume(user != spender);
        vm.assume(user != defaultData.owner);
        vm.assume(spender != defaultData.owner);
        vm.assume(mintAmount > 0 && mintAmount <= type(uint128).max);
        vm.assume(approveAmount <= type(uint128).max);

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, user);
        vm.stopPrank();

        vm.startPrank(user);
        bool success = ltv.approve(spender, approveAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.allowance(user, spender), approveAmount);
    }

    function testFuzz_transferFrom(
        DefaultTestData memory defaultData,
        address owner,
        address spender,
        address recipient,
        uint256 mintAmount,
        uint256 approveAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(owner != spender && owner != recipient && spender != recipient);
        vm.assume(owner != defaultData.owner);
        vm.assume(spender != defaultData.owner);
        vm.assume(recipient != defaultData.owner);
        vm.assume(mintAmount > 0 && mintAmount <= type(uint128).max);
        vm.assume(approveAmount <= type(uint128).max);
        vm.assume(transferAmount <= approveAmount && transferAmount <= mintAmount);

        vm.startPrank(defaultData.owner);
        ltv.mintFreeTokens(mintAmount, owner);
        vm.stopPrank();

        vm.startPrank(owner);
        ltv.approve(spender, approveAmount);
        vm.stopPrank();

        vm.startPrank(spender);
        bool success = ltv.transferFrom(owner, recipient, transferAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.balanceOf(owner), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
        assertEq(ltv.allowance(owner, spender), approveAmount - transferAmount);
    }
}
