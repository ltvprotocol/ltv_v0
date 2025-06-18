// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "src/errors/IERC20Errors.sol";

contract TransferFromTest is BaseTest, IERC20Errors {
    function test_notTransferWithoutApprove(DefaultTestData memory defaultData, address user, uint256 transferAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(transferAmount > 0);

        address owner = defaultData.owner;

        deal(address(ltv), owner, transferAmount);
        deal(address(ltv), user, transferAmount);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, owner, 0, transferAmount));
        ltv.transferFrom(user, owner, transferAmount);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, user, 0, transferAmount));
        ltv.transferFrom(owner, user, transferAmount);
    }

    function test_transferWithApprove(DefaultTestData memory defaultData, address user, uint256 transferAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount < type(uint256).max);

        address owner = defaultData.owner;

        deal(address(ltv), owner, transferAmount);

        vm.prank(owner);
        ltv.approve(user, transferAmount);

        vm.prank(user);
        bool success = ltv.transferFrom(owner, user, transferAmount);
        assertTrue(success);

        assertEq(ltv.allowance(owner, user), 0);
    }

    function test_smallApproveBigTransfer(DefaultTestData memory defaultData, address user, uint256 transferAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount % 10 == 0);

        address owner = defaultData.owner;

        deal(address(ltv), owner, transferAmount);

        vm.prank(owner);
        uint256 approveAmount = transferAmount / 10;
        ltv.approve(user, approveAmount);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientAllowance.selector, user, approveAmount, transferAmount)
        );
        ltv.transferFrom(owner, user, transferAmount);

        assertEq(ltv.allowance(owner, user), approveAmount);
    }

    function test_transferFromForSameUser(DefaultTestData memory defaultData, address user, uint256 transferAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount < type(uint256).max);

        deal(address(ltv), user, transferAmount);

        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, user, 0, transferAmount));
        ltv.transferFrom(user, user, transferAmount);

        ltv.approve(user, transferAmount);
        ltv.transferFrom(user, user, transferAmount);

        vm.stopPrank();

        assertEq(ltv.allowance(user, user), 0);
    }

    function test_partiallySpendAllowance(
        DefaultTestData memory defaultData,
        address user,
        uint256 approveAmount,
        uint256 transferAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(transferAmount > 0);
        vm.assume(approveAmount > transferAmount);
        vm.assume(approveAmount < type(uint256).max);

        address owner = defaultData.owner;
        deal(address(ltv), owner, approveAmount);

        vm.prank(owner);
        ltv.approve(user, approveAmount);

        vm.prank(user);
        bool success = ltv.transferFrom(owner, user, transferAmount);
        assertTrue(success);

        uint256 remainingAllowance = approveAmount - transferAmount;
        assertEq(ltv.allowance(owner, user), remainingAllowance);
    }

    function test_transferZeroAmount(DefaultTestData memory defaultData, address user, uint256 approveAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(approveAmount > 0);

        address owner = defaultData.owner;

        deal(address(ltv), owner, approveAmount);

        vm.prank(owner);
        ltv.approve(user, approveAmount);

        vm.prank(user);
        bool success = ltv.transferFrom(owner, user, 0);
        assertTrue(success);

        assertEq(ltv.allowance(owner, user), approveAmount);

        assertEq(ltv.balanceOf(owner), approveAmount);
        assertEq(ltv.balanceOf(user), 0);
    }

    function test_notTransferToZeroAddress(DefaultTestData memory defaultData, address user, uint256 approveAmount)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(approveAmount > 0);

        address owner = defaultData.owner;

        deal(address(ltv), owner, approveAmount);

        vm.prank(owner);
        ltv.approve(user, approveAmount);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(TransferToZeroAddress.selector));
        ltv.transferFrom(owner, address(0), approveAmount);
    }
}
