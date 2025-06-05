// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract TransferTest is BaseTest {
    function testFuzz_mintTransferRedeem(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(mintAmount > 0 && mintAmount <= 10 ** 15);
        vm.assume(transferAmount > 0);

        deal(address(borrowToken), userA, mintAmount);

        vm.startPrank(userA);
        borrowToken.approve(address(ltv), mintAmount);
        uint256 sharesReceived = ltv.deposit(mintAmount, userA);
        vm.stopPrank();

        vm.assume(transferAmount <= sharesReceived);

        uint256 userABalance = ltv.balanceOf(userA);
        assertEq(userABalance, sharesReceived);

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userB, transferAmount);

        vm.startPrank(userA);
        bool transferSuccess = ltv.transfer(userB, transferAmount);
        vm.stopPrank();

        assertTrue(transferSuccess);
        assertEq(ltv.balanceOf(userB), transferAmount);
        assertEq(ltv.balanceOf(userA), sharesReceived - transferAmount);

        uint256 sharesToRedeem = transferAmount;
        uint256 maxRedeemable = ltv.maxRedeem(userB);

        if (maxRedeemable >= sharesToRedeem) {
            uint256 expectedAssets = ltv.previewRedeem(sharesToRedeem);

            if (expectedAssets > 0) {
                vm.startPrank(userB);
                uint256 redeemedAssets = ltv.redeem(sharesToRedeem, userB, userB);
                vm.stopPrank();

                assertTrue(redeemedAssets > 0);
                assertEq(ltv.balanceOf(userB), 0);
            }
        }
    }

    function testFuzz_failedTransferInsufficientBalance(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(transferAmount > 0);

        vm.startPrank(userB);
        vm.expectRevert(stdError.arithmeticError);
        ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), 0);
        assertEq(ltv.balanceOf(userB), 0);
    }

    function testFuzz_zeroTransferWithEvents(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 mintAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(mintAmount > 0);

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

    function testFuzz_selfTransferWithEvents(
        DefaultTestData memory defaultData,
        address userA,
        uint128 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);

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

    function testFuzz_transferToZeroAddressFails(
        DefaultTestData memory defaultData,
        address userA,
        uint128 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);

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

    function testFuzz_comprehensiveERC20(
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
        vm.assume(mintAmount > 0 && mintAmount <= type(uint128).max);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);
        vm.assume(approveAmount >= transferAmount && approveAmount < type(uint256).max);

        ltv.mintFreeTokens(mintAmount, owner);

        vm.startPrank(owner);
        uint256 directTransferAmount = transferAmount / 2;
        bool transferSuccess = ltv.transfer(recipient, directTransferAmount);
        assertTrue(transferSuccess);
        vm.stopPrank();

        assertEq(ltv.balanceOf(owner), mintAmount - directTransferAmount);
        assertEq(ltv.balanceOf(recipient), directTransferAmount);

        vm.startPrank(owner);
        bool approveSuccess = ltv.approve(spender, approveAmount);
        assertTrue(approveSuccess);
        vm.stopPrank();

        assertEq(ltv.allowance(owner, spender), approveAmount);

        uint256 remainingTransfer = transferAmount - directTransferAmount;
        vm.startPrank(spender);
        bool transferFromSuccess = ltv.transferFrom(owner, recipient, remainingTransfer);
        assertTrue(transferFromSuccess);
        vm.stopPrank();

        assertEq(ltv.balanceOf(owner), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
        assertEq(ltv.allowance(owner, spender), approveAmount - remainingTransfer);
    }
}
