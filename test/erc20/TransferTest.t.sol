// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {stdError} from "forge-std/StdError.sol";
import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";
import {IERC20Errors} from "src/errors/IERC20Errors.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TransferTest is BaseTest {
    using SafeERC20 for IERC20;

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
        ltv.setmaxSafeLtv(1, 1);
        ltv.mintFreeTokens(mintAmount, userA);
        vm.stopPrank();

        transferAmount = transferAmount % mintAmount;

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(userA, userB, transferAmount);

        vm.prank(userA);
        IERC20(address(ltv)).safeTransfer(userB, transferAmount);

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
        /// forge-lint: disable-next-line
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
        IERC20(address(ltv)).safeTransfer(userB, 0);
        vm.stopPrank();

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
        IERC20(address(ltv)).safeTransfer(userA, transferAmount);
        vm.stopPrank();

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
        /// forge-lint: disable-next-line
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
        IERC20(address(ltv)).safeTransfer(recipient, transferAmount);
        vm.stopPrank();

        assertEq(ltv.balanceOf(owner), mintAmount - transferAmount);
        assertEq(ltv.balanceOf(recipient), transferAmount);
    }
}
