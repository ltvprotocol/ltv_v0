// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/errors/IERC20Errors.sol";

contract TransferTest is BaseTest {
    function testFuzz_mintTransferRedeem(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);

        deal(address(borrowToken), userA, type(uint256).max);

        vm.startPrank(defaultData.governor);
        ltv.setMaxSafeLTV(1, 1);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        transferAmount = transferAmount % mintAmount;

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userB, transferAmount);

        vm.prank(userA);
        bool transferSuccess = ltv.transfer(userB, transferAmount);

        assertTrue(transferSuccess);
        assertEq(ltv.balanceOf(userB), transferAmount);
        assertEq(ltv.balanceOf(userA), mintAmount - transferAmount);

        assertEq(borrowToken.balanceOf(userB), 0);
        uint256 minimumSharesToGetBorrow = ltv.previewWithdraw(1);
        vm.prank(userB);
        ltv.redeem(transferAmount, userB, userB);
        if (transferAmount >= minimumSharesToGetBorrow) {
            assertGt(borrowToken.balanceOf(userB), 0);
        }
    }

    function testFuzz_failedTransferInsufficientBalance(
        DefaultTestData memory defaultData,
        address userA,
        address userB,
        uint128 mintAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(mintAmount > 0);
        vm.assume(transferAmount > 0);

        ltv.mintFreeTokens(mintAmount, userA);

        vm.startPrank(userB);
        vm.expectRevert(stdError.arithmeticError);
        ltv.transfer(userA, transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), mintAmount);
        assertEq(ltv.balanceOf(userB), 0);
    }

    function testFuzz_zeroTransferWithEvents(DefaultTestData memory defaultData, address userA, address userB)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);

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
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(mintAmount > 0);
        transferAmount = transferAmount % mintAmount;

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
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(mintAmount > 0);
        transferAmount = transferAmount % mintAmount;

        ltv.mintFreeTokens(mintAmount, userA);
        uint256 initialBalanceUserA = ltv.balanceOf(userA);
        uint256 initialBalanceZero = ltv.balanceOf(address(0));

        vm.startPrank(userA);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.TransferToZeroAddress.selector));
        ltv.transfer(address(0), transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(userA), initialBalanceUserA);
        assertEq(ltv.balanceOf(address(0)), initialBalanceZero);
    }

    function testFuzz_comprehensiveERC20(
        DefaultTestData memory defaultData,
        address owner,
        address recipient,
        uint128 mintAmount,
        uint128 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(owner != address(0));
        vm.assume(recipient != address(0));
        vm.assume(owner != recipient);
        vm.assume(mintAmount > 0);
        transferAmount = transferAmount % mintAmount;

        ltv.mintFreeTokens(mintAmount, owner);

        vm.startPrank(owner);
        bool transferSuccess = ltv.transfer(recipient, transferAmount);
        assertTrue(transferSuccess);
        vm.stopPrank();

        assertEq(ltv.balanceOf(owner), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
    }
}
