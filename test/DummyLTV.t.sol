// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../src/dummy/DummyOracle.sol';
import 'forge-std/Test.sol';
import {MockERC20} from 'forge-std/mocks/MockERC20.sol';
import {MockDummyLending} from './utils/MockDummyLending.sol';
import './utils/MockDummyLTV.sol';
import '../src/Constants.sol';

contract DummyLTVTest is Test {
    MockDummyLTV public dummyLTV;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;

    modifier initializeTest(
        address owner,
        address user,
        uint256 borrowAmount
    ) {
        vm.assume(owner != address(0));
        vm.assume(user != address(0));
        vm.assume(user != owner);
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
            oracle
        );

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 100 * 10 ** 18);
        oracle.setAssetPrice(address(collateralToken), 200 * 10 ** 18);

        deal(address(borrowToken), address(lendingProtocol), borrowAmount);
        deal(address(borrowToken), user, borrowAmount);

        lendingProtocol.setSupplyBalance(address(collateralToken), borrowAmount * 5 * 4);
        lendingProtocol.setBorrowBalance(address(borrowToken), borrowAmount * 10 * 3);

        dummyLTV.mintFreeTokens(borrowAmount * 100000, owner);

        vm.startPrank(user);
        _;
    }

    function test_totalAssets(
        address owner,
        address user,
        uint160 amount
    ) public initializeTest(owner, user, 0) {
        assertEq(dummyLTV.totalAssets(), 1);
        lendingProtocol.setSupplyBalance(address(collateralToken), uint256(amount) * 2);
        lendingProtocol.setBorrowBalance(address(borrowToken), amount);
        assertEq(dummyLTV.totalAssets(), 3 * uint256(amount) * 100 + 1);
    }

    function test_basicCmbc(
        address owner,
        address user,
        uint112 amount
    ) public initializeTest(owner, user, amount) {
        // auction + current state = balanced vault. State is balanced. Auction is also satisfies LTV(not really realistic but acceptable)
        dummyLTV.setFutureBorrowAssets(7500);
        dummyLTV.setFutureCollateralAssets(5005);
        dummyLTV.mintFreeTokens(2500 * 10000, owner);

        vm.roll(20);
        dummyLTV.setStartAuction(10);
        dummyLTV.setFutureRewardCollateralAssets(-5);

        borrowToken.approve(address(dummyLTV), amount);
        dummyLTV.deposit(amount, user);

        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 10000);
    }

    function test_convertToAssets(
        address owner,
        address user,
        uint112 amount
    ) public initializeTest(owner, user, amount) {
        dummyLTV.setFutureBorrowAssets(7500);
        dummyLTV.setFutureCollateralAssets(5000);
        dummyLTV.mintFreeTokens(2500 * 10000, owner);

        assertEq(dummyLTV.convertToAssets(uint256(amount) * 100), amount);
    }

    function test_convertToShares(
        address owner,
        address user,
        uint112 amount
    ) public initializeTest(owner, user, amount) {
        dummyLTV.setFutureBorrowAssets(7500);
        dummyLTV.setFutureCollateralAssets(5005);
        dummyLTV.mintFreeTokens(2500 * 10000, owner);

        vm.roll(20);
        dummyLTV.setStartAuction(10);
        dummyLTV.setFutureRewardCollateralAssets(-5);

        assertEq(dummyLTV.convertToShares(amount), uint256(amount) * 100);
    }

    function test_previewDeposit(
        address owner,
        address user,
        uint112 amount
    ) public initializeTest(owner, user, amount) {
        dummyLTV.setFutureBorrowAssets(7500);
        dummyLTV.setFutureCollateralAssets(5005);
        dummyLTV.mintFreeTokens(2500 * 10000, owner);

        vm.roll(20);
        dummyLTV.setStartAuction(10);
        dummyLTV.setFutureRewardCollateralAssets(-5);

        assertEq(dummyLTV.previewDeposit(amount), uint256(amount) * 10000);
    }

    function test_previewMint(
        address owner,
        address user,
        uint112 amount
    ) public initializeTest(owner, user, amount) {
        dummyLTV.setFutureBorrowAssets(7500);
        dummyLTV.setFutureCollateralAssets(5005);
        dummyLTV.mintFreeTokens(2500 * 10000, owner);

        vm.roll(20);
        dummyLTV.setStartAuction(10);
        dummyLTV.setFutureRewardCollateralAssets(-5);

        assertEq(dummyLTV.previewMint(uint256(amount) * 10000), amount);
    }
}
