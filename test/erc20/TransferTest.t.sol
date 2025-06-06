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
        vm.assume(userA != defaultData.feeCollector);
        vm.assume(userB != defaultData.feeCollector);

        uint256 mintAmount = 10 ** 17;
        uint256 transferAmount = 5 * 10 ** 16;

        ltv.mintFreeTokens(mintAmount, userA);
        uint256 userABalance = ltv.balanceOf(userA);
        assertEq(userABalance, mintAmount);

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userB, transferAmount);

        vm.startPrank(userA);
        bool transferSuccess = ltv.transfer(userB, transferAmount);
        vm.stopPrank();

        assertTrue(transferSuccess);
        assertEq(ltv.balanceOf(userB), transferAmount);
        assertEq(ltv.balanceOf(userA), mintAmount - transferAmount);
    }

    function test_failedTransferInsufficientBalance(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);
        vm.assume(userB != defaultData.feeCollector);

        uint256 transferAmount = 100;

        vm.startPrank(userB);
        vm.expectRevert(stdError.arithmeticError);
        ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), 0);
        assertEq(ltv.balanceOf(userB), 0);
    }

    function test_zeroTransferWithEvents(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);
        vm.assume(userB != defaultData.feeCollector);

        uint256 mintAmount = 10 ** 17;

        ltv.mintFreeTokens(mintAmount, userA);

        uint256 initialBalanceA = ltv.balanceOf(userA);
        uint256 initialBalanceB = ltv.balanceOf(userB);

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userB, 0);

        vm.startPrank(userA);
        bool zeroTransferSuccess = ltv.transfer(userB, 0);
        vm.stopPrank();

        assertTrue(zeroTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalanceA);
        assertEq(ltv.balanceOf(userB), initialBalanceB);
    }

    function test_selfTransferWithEvents(DefaultTestData memory defaultData, address userA)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);

        uint256 mintAmount = 10 ** 17;
        uint256 transferAmount = 5 * 10 ** 16;

        ltv.mintFreeTokens(mintAmount, userA);
        uint256 initialBalance = ltv.balanceOf(userA);

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userA, transferAmount);

        vm.startPrank(userA);
        bool selfTransferSuccess = ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertTrue(selfTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalance);
    }

    function test_transferToZeroAddressFails(DefaultTestData memory defaultData, address userA)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);

        uint256 mintAmount = 10 ** 17;
        uint256 transferAmount = 5 * 10 ** 16;

        ltv.mintFreeTokens(mintAmount, userA);
        uint256 initialBalanceUserA = ltv.balanceOf(userA);
        uint256 initialBalanceZero = ltv.balanceOf(address(0));

        vm.startPrank(userA);
        vm.expectRevert(abi.encodeWithSignature("TransferToZeroAddress()"));
        ltv.transfer(address(0), transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), initialBalanceUserA);
        assertEq(ltv.balanceOf(address(0)), initialBalanceZero);
    }

    function testFuzz_transferWithEvents(
        DefaultTestData memory defaultData,
        address user,
        address recipient,
        uint128 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(recipient != address(0));
        vm.assume(user != recipient);
        vm.assume(user != defaultData.owner);
        vm.assume(recipient != defaultData.owner);
        vm.assume(user != defaultData.feeCollector);
        vm.assume(recipient != defaultData.feeCollector);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);

        ltv.mintFreeTokens(mintAmount, user);

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(user, recipient, transferAmount);

        vm.startPrank(user);
        bool success = ltv.transfer(recipient, transferAmount);
        vm.stopPrank();

        assertTrue(success);
        assertEq(ltv.balanceOf(user), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
    }

    function testFuzz_approveAmount(
        DefaultTestData memory defaultData,
        address user,
        address spender,
        uint128 mintAmount,
        uint256 approveAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(spender != address(0));
        vm.assume(user != spender);
        vm.assume(user != defaultData.owner);
        vm.assume(spender != defaultData.owner);
        vm.assume(user != defaultData.feeCollector);
        vm.assume(spender != defaultData.feeCollector);
        vm.assume(mintAmount > 0);

        ltv.mintFreeTokens(mintAmount, user);

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
        uint128 mintAmount,
        uint256 approveAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(owner != spender && spender != recipient && owner != recipient);
        vm.assume(owner != defaultData.owner);
        vm.assume(spender != defaultData.owner);
        vm.assume(recipient != defaultData.owner);
        vm.assume(owner != defaultData.feeCollector);
        vm.assume(spender != defaultData.feeCollector);
        vm.assume(recipient != defaultData.feeCollector);
        vm.assume(mintAmount > 0);
        vm.assume(approveAmount > 0 && approveAmount < type(uint256).max);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount && transferAmount <= approveAmount);

        ltv.mintFreeTokens(mintAmount, owner);

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
