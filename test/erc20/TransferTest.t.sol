// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract TransferTest is BaseTest {
    
    function test_mintTransferRedeem(
        DefaultTestData memory defaultData,
        address userA,
        address userB
    ) public testWithPredefinedDefaultValues(defaultData) {
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
        assertEq(ltv.balanceOf(userA), mintAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(userA, userB, transferAmount);
        
        vm.startPrank(userA);
        bool transferSuccess = ltv.transfer(userB, transferAmount);
        vm.stopPrank();
        
        assertTrue(transferSuccess);
        assertEq(ltv.balanceOf(userB), transferAmount);
        assertEq(ltv.balanceOf(userA), mintAmount - transferAmount);
        
        deal(address(borrowToken), userB, type(uint112).max);
        vm.startPrank(userB);
        borrowToken.approve(address(ltv), type(uint112).max);
        
        uint256 smallDeposit = 1000;
        ltv.deposit(smallDeposit, userB);
        
        ltv.redeem(transferAmount, userB, userB);
        vm.stopPrank();
    }
    
    function test_failedTransferInsufficientBalance(
        DefaultTestData memory defaultData,
        address userA,
        address userB
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userB != address(0));
        vm.assume(userA != userB);
        vm.assume(userA != defaultData.owner);
        vm.assume(userB != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);
        vm.assume(userB != defaultData.feeCollector);
        
        uint256 transferAmount = 100;
        
        vm.startPrank(userB);
        vm.expectRevert();
        ltv.transfer(userA, transferAmount);
        vm.stopPrank();
        
        assertEq(ltv.balanceOf(userA), 0);
        assertEq(ltv.balanceOf(userB), 0);
    }
    
    function test_zeroTransferWithEvents(
        DefaultTestData memory defaultData,
        address userA,
        address userB
    ) public testWithPredefinedDefaultValues(defaultData) {
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
        emit Transfer(userA, userB, 0);
        
        vm.startPrank(userA);
        bool zeroTransferSuccess = ltv.transfer(userB, 0);
        vm.stopPrank();
        
        assertTrue(zeroTransferSuccess);
        assertEq(ltv.balanceOf(userA), initialBalanceA);
        assertEq(ltv.balanceOf(userB), initialBalanceB);
    }
    
    function test_selfTransferWithEvents(
        DefaultTestData memory defaultData,
        address userA
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);
        
        uint256 mintAmount = 10 ** 17;
        uint256 transferAmount = 5 * 10 ** 16;
        
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
    
    function test_transferToZeroAddressFails(
        DefaultTestData memory defaultData,
        address userA
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(userA != address(0));
        vm.assume(userA != defaultData.owner);
        vm.assume(userA != defaultData.feeCollector);
        
        uint256 mintAmount = 10 ** 17;
        uint256 transferAmount = 5 * 10 ** 16;
        
        ltv.mintFreeTokens(mintAmount, userA);
        uint256 initialBalanceUserA = ltv.balanceOf(userA);
        uint256 initialBalanceZero = ltv.balanceOf(address(0));
        
        vm.startPrank(userA);
        bool success = ltv.transfer(address(0), transferAmount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(ltv.balanceOf(userA), initialBalanceUserA - transferAmount);
        assertEq(ltv.balanceOf(address(0)), initialBalanceZero + transferAmount);
    }
    
    function testFuzz_transferWithEvents(
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
        vm.assume(user != defaultData.feeCollector);
        vm.assume(recipient != defaultData.feeCollector);
        vm.assume(mintAmount > 0 && mintAmount <= 10 ** 18);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);
        
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
        vm.assume(owner != defaultData.feeCollector);
        vm.assume(spender != defaultData.feeCollector);
        vm.assume(recipient != defaultData.feeCollector);
        vm.assume(mintAmount > 0 && mintAmount <= 10 ** 18);
        vm.assume(approveAmount > 0 && approveAmount <= 10 ** 18);
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
        
        if (approveAmount != type(uint256).max) {
            assertEq(ltv.allowance(owner, spender), approveAmount - transferAmount);
        }
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}