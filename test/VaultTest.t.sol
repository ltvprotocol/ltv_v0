// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract VaultTest is BalancedTest {
    using SafeERC20 for IERC20;

    function test_totalAssets(address owner, address user, uint160 amount)
        public
        initializeBalancedTest(owner, user, 0, 0, 0, 0)
    {
        assertEq(dummyLtv.totalAssets(), 0);
        lendingProtocol.setSupplyBalance(address(collateralToken), uint256(amount) * 2);
        lendingProtocol.setBorrowBalance(address(borrowToken), amount);
        assertEq(dummyLtv.totalAssets(), 3 * uint256(amount));
    }

    function test_convertToAssets(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLtv.convertToAssets(uint256(amount)), amount);
    }

    function test_convertToShares(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLtv.convertToShares(amount), uint256(amount));
    }

    function test_previewDeposit(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLtv.previewDeposit(amount), uint256(amount));
    }

    function test_previewMint(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        assertEq(dummyLtv.previewMint(uint256(amount)), amount);
    }

    function test_basicCmbcDeposit(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        // auction + current state = balanced vault. State is balanced. Auction is also satisfies LTV(not really realistic but acceptable)
        borrowToken.approve(address(dummyLtv), amount);
        dummyLtv.deposit(amount, user);

        assertEq(dummyLtv.balanceOf(user), uint256(amount));
    }

    function test_basicCmbcMint(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 9500, 9500, -1000)
    {
        borrowToken.approve(address(dummyLtv), amount);
        dummyLtv.mint(uint256(amount), user);

        assertEq(dummyLtv.balanceOf(user), uint256(amount));
    }

    function test_previewWithdraw(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        assertEq(dummyLtv.previewWithdraw(uint256(amount)), uint256(amount));
    }

    function test_previewRedeem(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        assertEq(dummyLtv.previewRedeem(uint256(amount)), uint256(amount));
    }

    function test_withdraw(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 3);
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, uint256(amount));

        vm.startPrank(user);
        assertEq(dummyLtv.balanceOf(user), uint256(amount));
        dummyLtv.withdraw(uint256(amount - 3), user, user);
        assertEq(dummyLtv.balanceOf(user), 3);
    }

    function test_redeem(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, -9500, -9500, 1000)
    {
        vm.assume(amount > 0);
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, uint256(amount));

        vm.startPrank(user);
        assertEq(dummyLtv.balanceOf(user), uint256(amount));
        dummyLtv.redeem(uint256(amount), user, user);
        assertEq(dummyLtv.balanceOf(user), 0);
    }

    function test_zeroAuction(address owner, address user, uint112 amount)
        public
        initializeBalancedTest(owner, user, amount, 0, 0, 0)
    {
        vm.assume(amount > 0);
        assertEq(dummyLtv.previewDeposit(amount), uint256(amount));
    }

    function test_maxDeposit(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000)
    {
        assertEq(dummyLtv.maxDeposit(user), 994750);
        borrowToken.approve(address(dummyLtv), type(uint112).max);
        dummyLtv.deposit(dummyLtv.maxDeposit(user), user);
    }

    function test_maxMint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        slippageProvider.setCollateralSlippage(10 ** 16);

        vm.startPrank(user);
        assertEq(dummyLtv.maxMint(user), 956118);
        borrowToken.approve(address(dummyLtv), type(uint112).max);
        dummyLtv.mint(dummyLtv.maxMint(user), user);
    }

    function test_maxWithdraw(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, dummyLtv.balanceOf(owner));

        assertEq(dummyLtv.maxWithdraw(user), 600050);
        vm.startPrank(user);
        dummyLtv.withdraw(dummyLtv.maxWithdraw(user), user, user);
    }

    function test_maxRedeem(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, dummyLtv.balanceOf(owner));
        slippageProvider.setBorrowSlippage(10 ** 16);

        assertEq(dummyLtv.maxRedeem(user), 625049);
        vm.startPrank(user);
        dummyLtv.redeem(dummyLtv.maxRedeem(user), user, user);
    }

    function test_maxDepositFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLtv)).governor());
        dummyLtv.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLtv.maxDeposit(user), 10 ** 6);
    }

    function test_maxMintFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLtv)).governor());
        dummyLtv.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLtv.maxMint(user), dummyLtv.previewDeposit(10 ** 6));
    }

    function test_maxDepositCollateralFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLtv)).governor());
        dummyLtv.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLtv.maxDepositCollateral(user), 5 * 10 ** 5);
    }

    function test_maxMintCollateralFinalBorder(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLtv)).governor());
        dummyLtv.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLtv.maxMintCollateral(user), dummyLtv.previewDepositCollateral(5 * 10 ** 5));
    }

    function test_totalAssetsCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(dummyLtv.totalAssetsCollateral(), 5 * 10 ** 17);
    }

    function test_maxWithdrawCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, dummyLtv.balanceOf(owner));

        assertEq(dummyLtv.maxWithdrawCollateral(user), 333361);
    }

    function test_maxRedeemCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        IERC20(address(dummyLtv)).safeTransfer(user, dummyLtv.balanceOf(owner));

        assertEq(dummyLtv.maxRedeemCollateral(user), 333361 * 2 - 6);
    }

    function test_totalAssetsWithBool(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLtv)).totalAssets(true), 10 ** 18);
    }

    function test_totalAssetsCollateralWithBool(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(ILTV(address(dummyLtv)).totalAssetsCollateral(true), 5 * 10 ** 17);
    }
}
