// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./utils/BalancedTest.t.sol";

contract VaultTest is BalancedTest {
    function test_totalAssets(address owner, address user, uint160 amount)
        public
        initializeBalancedTest(owner, user, 0, 0, 0, 0)
    {
        assertEq(dummyLTV.totalAssets(), 0);
        lendingProtocol.setSupplyBalance(address(collateralToken), uint256(amount) * 2);
        lendingProtocol.setBorrowBalance(address(borrowToken), amount);
        assertEq(dummyLTV.totalAssets(), 3 * uint256(amount));
    }

    function test_convertToAssets(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLTV.convertToAssets(uint256(amount)), amount);
    }

    function test_convertToShares(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLTV.convertToShares(amount), uint256(amount));
    }

    function test_previewDeposit(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLTV.previewDeposit(amount), uint256(amount));
    }

    function test_previewMint(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLTV.previewMint(uint256(amount)), amount);
    }

    function test_basicCmbcDeposit(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        // auction + current state = balanced vault. State is balanced. Auction is also satisfies LTV(not really realistic but acceptable)
        borrowToken.approve(address(dummyLTV), amount);
        dummyLTV.deposit(amount, user);

        assertEq(dummyLTV.balanceOf(user), uint256(amount));
    }

    function test_basicCmbcMint(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        borrowToken.approve(address(dummyLTV), amount);
        dummyLTV.mint(uint256(amount), user);

        assertEq(dummyLTV.balanceOf(user), uint256(amount));
    }

    function test_previewWithdraw(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        assertEq(dummyLTV.previewWithdraw(uint256(amount)), uint256(amount));
    }

    function test_previewRedeem(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        assertEq(dummyLTV.previewRedeem(uint256(amount)), uint256(amount));
    }

    function test_withdraw(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 3);
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, uint256(amount));

        vm.startPrank(user);
        assertEq(dummyLTV.balanceOf(user), uint256(amount));
        dummyLTV.withdraw(uint256(amount - 3), user, user);
        assertEq(dummyLTV.balanceOf(user), 3);
    }

    function test_redeem(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, uint256(amount));

        vm.startPrank(user);
        assertEq(dummyLTV.balanceOf(user), uint256(amount));
        dummyLTV.redeem(uint256(amount), user, user);
        assertEq(dummyLTV.balanceOf(user), 0);
    }

    function test_zeroAuction(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 0, 0, 0)
    {
        vm.assume(amount > 0);
        assertEq(dummyLTV.previewDeposit(amount), uint256(amount));
    }

    function test_maxDeposit(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000)
    {
        assertEq(dummyLTV.maxDeposit(user), 994750);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.deposit(dummyLTV.maxDeposit(user), user);
    }

    function test_maxMint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        slippageProvider.setCollateralSlippage(10 ** 16);

        vm.startPrank(user);
        assertEq(dummyLTV.maxMint(user), 956118);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.mint(dummyLTV.maxMint(user), user);
    }

    function test_maxWithdraw(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));

        assertEq(dummyLTV.maxWithdraw(user), 600050);
        vm.startPrank(user);
        dummyLTV.withdraw(dummyLTV.maxWithdraw(user), user, user);
    }

    function test_maxRedeem(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));
        slippageProvider.setBorrowSlippage(10 ** 16);

        assertEq(dummyLTV.maxRedeem(user), 625049);
        vm.startPrank(user);
        dummyLTV.redeem(dummyLTV.maxRedeem(user), user, user);
    }

    function test_maxDepositFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxDeposit(user), 10 ** 6);
    }

    function test_maxMintFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxMint(user), dummyLTV.previewDeposit(10 ** 6));
    }

    function test_maxDepositCollateralFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxDepositCollateral(user), 5 * 10 ** 5);
    }

    function test_maxMintCollateralFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxMintCollateral(user), dummyLTV.previewDepositCollateral(5 * 10 ** 5));
    }

    function test_totalAssetsCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(dummyLTV.totalAssetsCollateral(), 5 * 10 ** 17);
    }

    function test_maxWithdrawCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));

        assertEq(dummyLTV.maxWithdrawCollateral(user), 333361);
    }

    function test_maxRedeemCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));

        assertEq(dummyLTV.maxRedeemCollateral(user), 333361 * 2 - 6);
    }

    function test_totalAssetsWithBool(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLTV)).totalAssets(true), 10 ** 18);
    }

    function test_totalAssetsCollateralWithBool(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLTV)).totalAssetsCollateral(true), 5 * 10 ** 17);
    }
}
