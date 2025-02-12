// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../src/ltv_lendings/DummyLTV.sol";
import "../src/dummy/DummyOracle.sol";
import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {MockDummyLending} from "./utils/MockDummyLending.sol";
import "./utils/MockDummyLTV.sol";
import "../src/Constants.sol";

contract DummyLTVTest is Test {
    MockDummyLTV public dummyLTV;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;

    modifier initializeBalancedTest(
        address owner,
        address user,
        uint256 borrowAmount,
        int256 futureBorrow,
        int256 futureCollateral,
        int256 auctionReward
    ) {
        vm.assume(owner != address(0));
        vm.assume(user != address(0));
        vm.assume(user != owner);
        vm.assume(int256(borrowAmount) >= futureBorrow);
        collateralToken = new MockERC20();
        collateralToken.initialize('Collateral', 'COL', 18);
        borrowToken = new MockERC20();
        borrowToken.initialize('Borrow', 'BOR', 18);

        lendingProtocol = new MockDummyLending(owner);
        oracle = IDummyOracle(new DummyOracle(owner));

        dummyLTV = new MockDummyLTV(
            owner,
            address(collateralToken),
            address(borrowToken),
            lendingProtocol,
            oracle,
            0,
            0
        );

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 100 * 10 ** 18);
        oracle.setAssetPrice(address(collateralToken), 200 * 10 ** 18);

        deal(address(borrowToken), address(lendingProtocol), type(uint112).max);
        deal(address(borrowToken), user, type(uint112).max);

        dummyLTV.mintFreeTokens(borrowAmount * 1000, owner);

        vm.roll(20);
        dummyLTV.setStartAuction(10);
        dummyLTV.setFutureBorrowAssets(futureBorrow);
        dummyLTV.setFutureCollateralAssets(futureCollateral / 2);
        
        if (futureBorrow < 0) {
            lendingProtocol.setSupplyBalance(address(collateralToken), uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2));
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow - auctionReward));
            dummyLTV.setFutureRewardBorrowAssets(auctionReward);
        } else {
            lendingProtocol.setSupplyBalance(address(collateralToken), uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2 - auctionReward / 2));
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow));
            dummyLTV.setFutureRewardCollateralAssets(auctionReward / 2);
        }

        dummyLTV.setMaxSafeLTV(9*10**17);
        dummyLTV.setMinProfitLTV(5*10**17);
        dummyLTV.setTargetLTV(75*10**16);
        
        vm.startPrank(user);
        _;
    }

    function test_totalAssets(
        address owner,
        address user,
        uint160 amount
    ) public initializeBalancedTest(owner, user, 0, 0, 0, 0) {
        assertEq(dummyLTV.totalAssets(), 1);
        lendingProtocol.setSupplyBalance(address(collateralToken), uint256(amount) * 2);
        lendingProtocol.setBorrowBalance(address(borrowToken), amount);
        assertEq(dummyLTV.totalAssets(), 3 * uint256(amount) + 1);
    }

    function test_convertToAssets(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.convertToAssets(uint256(amount) * 100), amount);
    }

    function test_convertToShares(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.convertToShares(amount), uint256(amount) * 100);
    }

    function test_previewDeposit(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.previewDeposit(amount), uint256(amount) * 100); 
    }

    function test_previewMint(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.previewMint(uint256(amount) * 100), amount);
    }

    function test_basicCmbcDeposit(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        // auction + current state = balanced vault. State is balanced. Auction is also satisfies LTV(not really realistic but acceptable)
        borrowToken.approve(address(dummyLTV), amount);
        dummyLTV.deposit(amount, user);

        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 100);
    }

    function test_basicCmbcMint(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        borrowToken.approve(address(dummyLTV), amount);
        dummyLTV.mint(uint256(amount) * 100, user);

        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 100);
    }

    function test_previewWithdraw(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        assertEq(dummyLTV.previewWithdraw(uint256(amount)), uint256(amount) * 100);
    }

    function test_previewRedeem(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        assertEq(dummyLTV.previewRedeem(uint256(amount) * 100), uint256(amount));
    }

    function test_withdraw(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, uint256(amount) * 100);

        vm.startPrank(user);
        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 100);
        dummyLTV.withdraw(uint256(amount), user, user);
        assertEq(dummyLTV.balanceOf(user), 0);
    }

    function test_redeem(
        address owner,
        address user,
        uint112 amount
    ) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, uint256(amount) * 100);

        vm.startPrank(user);
        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 100);
        dummyLTV.redeem(uint256(amount) * 100, user, user);
        assertEq(dummyLTV.balanceOf(user), 0);
    }

    function test_zeroAuction(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 0, 0, 0) {
        assertEq(dummyLTV.previewDeposit(amount), uint256(amount) * 100);
    }

    function test_maxDeposit(address owner, address user) public initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000) {
        assertEq(dummyLTV.maxDeposit(user), 994750);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.deposit(dummyLTV.maxDeposit(user), user);
    }

    function test_maxMint(address owner, address user) public initializeBalancedTest(owner, user, 100000, 9500, 9500, -1000) {
        dummyLTV.setCollateralSlippage(10**16);

        assertEq(dummyLTV.maxMint(user), 956118 * 100);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.mint(dummyLTV.maxMint(user), user);
    }

    function test_maxWithdraw(address owner, address user) public initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));

        assertEq(dummyLTV.maxWithdraw(user), 600050);
        dummyLTV.withdraw(dummyLTV.maxWithdraw(user), user, user);
    }

    function test_maxRedeem(address owner, address user) public initializeBalancedTest(owner, user, 100000, -9500, -9500, 1000) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, dummyLTV.balanceOf(owner));
        dummyLTV.setBorrowSlippage(10**16);

        assertEq(dummyLTV.maxRedeem(user), 625052 * 100);
        dummyLTV.redeem(dummyLTV.maxRedeem(user), user, user);
    }


}
