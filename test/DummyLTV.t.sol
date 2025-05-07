// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../src/dummy/DummyOracle.sol';
import 'forge-std/Test.sol';
import {MockERC20} from 'forge-std/mocks/MockERC20.sol';
import {MockDummyLending} from './utils/MockDummyLending.t.sol';
import './utils/DummyLTV.t.sol';
import '../src/Constants.sol';
import '../src/dummy/DummyLendingConnector.sol';
import '../src/dummy/DummyOracleConnector.sol';
import '../src/utils/ConstantSlippageProvider.sol';
import '../src/utils/WhitelistRegistry.sol';
import '../src/utils/VaultBalanceAsLendingConnector.sol';
import '../src/utils/Timelock.sol';
import {ILTV} from '../src/interfaces/ILTV.sol';
import {ArchitectureBase} from './utils/ArchitectureBase.t.sol';

contract DummyLTVTest is ArchitectureBase {
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;
    ConstantSlippageProvider public slippageProvider;


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

        {
            DummyLendingConnector lendingConnector = new DummyLendingConnector(collateralToken, borrowToken, lendingProtocol);
            DummyOracleConnector oracleConnector = new DummyOracleConnector(collateralToken, borrowToken, oracle);

            address vaultBalanceAsLendingConnector = address(new VaultBalanceAsLendingConnector(collateralToken, borrowToken));
            slippageProvider = new ConstantSlippageProvider(0, 0, owner);

            State.StateInitData memory initData = State.StateInitData({
                collateralToken: address(collateralToken),
                borrowToken: address(borrowToken),
                feeCollector: owner,
                maxSafeLTV: 9 * 10 ** 17,
                minProfitLTV: 5 * 10 ** 17,
                targetLTV: 75 * 10 ** 16,
                lendingConnector: lendingConnector,
                oracleConnector: oracleConnector,
                maxGrowthFee: 10 ** 18 / 5,
                maxTotalAssetsInUnderlying: type(uint128).max,
                slippageProvider: slippageProvider,
                maxDeleverageFee: 2 * 10 ** 16,
                vaultBalanceAsLendingConnector: ILendingConnector(vaultBalanceAsLendingConnector)
            });

            dummyLTV = new DummyLTV(initData, owner);
        }

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 100 * 10 ** 18);
        oracle.setAssetPrice(address(collateralToken), 200 * 10 ** 18);

        deal(address(borrowToken), address(lendingProtocol), type(uint112).max);
        deal(address(borrowToken), user, type(uint112).max);
        deal(address(collateralToken), address(lendingProtocol), type(uint112).max);
        deal(address(collateralToken), user, type(uint112).max);

        dummyLTV.mintFreeTokens(borrowAmount * 1000, owner);

        vm.roll(Constants.AMOUNT_OF_STEPS);
        dummyLTV.setStartAuction(Constants.AMOUNT_OF_STEPS / 2);
        dummyLTV.setFutureBorrowAssets(futureBorrow);
        dummyLTV.setFutureCollateralAssets(futureCollateral / 2);

        if (futureBorrow < 0) {
            lendingProtocol.setSupplyBalance(address(collateralToken), uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2));
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow - auctionReward));
            dummyLTV.setFutureRewardBorrowAssets(auctionReward);
        } else {
            lendingProtocol.setSupplyBalance(
                address(collateralToken),
                uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2 - auctionReward / 2)
            );
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow));
            dummyLTV.setFutureRewardCollateralAssets(auctionReward / 2);
        }

        vm.startPrank(user);
        collateralToken.approve(address(dummyLTV), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        replaceImplementation();
        _;
    }

    function test_totalAssets(address owner, address user, uint160 amount) public initializeBalancedTest(owner, user, 0, 0, 0, 0) {
        assertEq(dummyLTV.totalAssets(), 1);
        lendingProtocol.setSupplyBalance(address(collateralToken), uint256(amount) * 2);
        lendingProtocol.setBorrowBalance(address(borrowToken), amount);
        assertEq(dummyLTV.totalAssets(), 3 * uint256(amount) + 1);
    }

    function test_convertToAssets(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.convertToAssets(uint256(amount) * 100), amount);
    }

    function test_convertToShares(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.convertToShares(amount), uint256(amount) * 100);
    }

    function test_previewDeposit(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
        assertEq(dummyLTV.previewDeposit(amount), uint256(amount) * 100);
    }

    function test_previewMint(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
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

    function test_basicCmbcMint(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, 9500, 9500, -1000) {
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

    function test_previewRedeem(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        assertEq(dummyLTV.previewRedeem(uint256(amount) * 100), uint256(amount));
    }

    function test_withdraw(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.transfer(user, uint256(amount) * 100);

        vm.startPrank(user);
        assertEq(dummyLTV.balanceOf(user), uint256(amount) * 100);
        dummyLTV.withdraw(uint256(amount), user, user);
        assertEq(dummyLTV.balanceOf(user), 0);
    }

    function test_redeem(address owner, address user, uint112 amount) public initializeBalancedTest(owner, user, amount, -9500, -9500, 1000) {
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
        vm.stopPrank();
        vm.startPrank(owner);
        slippageProvider.setCollateralSlippage(10 ** 16);

        vm.startPrank(user);
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
        slippageProvider.setBorrowSlippage(10 ** 16);

        assertEq(dummyLTV.maxRedeem(user), 625053 * 100);
        dummyLTV.redeem(dummyLTV.maxRedeem(user), user, user);
    }

    function test_executeDepositAuctionBorrow(address owner, address user) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        collateralToken.approve(address(dummyLTV), type(uint112).max);
        int256 expectedDeltaCollateral = dummyLTV.previewExecuteAuctionBorrow(-1000);
        int256 deltaCollateral = dummyLTV.executeAuctionBorrow(-1000);

        assertEq(deltaCollateral, -475);
        assertEq(expectedDeltaCollateral, deltaCollateral);
    }

    function test_executeDepositAuctionCollateral(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        collateralToken.approve(address(dummyLTV), type(uint112).max);
        int256 expectedDeltaBorrow = dummyLTV.previewExecuteAuctionCollateral(-475);
        int256 deltaBorrow = dummyLTV.executeAuctionCollateral(-475);

        assertEq(deltaBorrow, -1000);
        assertEq(expectedDeltaBorrow, deltaBorrow);
    }

    function test_executeWithdrawAuctionBorrow(address owner, address user) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        int256 deltaCollateral = dummyLTV.executeAuctionBorrow(950);

        assertEq(deltaCollateral, 500);
    }

    function test_executeWithdrawAuctionCollateral(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        int256 expectedDeltaBorrow = dummyLTV.previewExecuteAuctionCollateral(500);
        int256 deltaBorrow = dummyLTV.executeAuctionCollateral(500);

        assertEq(deltaBorrow, 950);
        assertEq(expectedDeltaBorrow, deltaBorrow);
    }

    function test_lowLevelNegativeAuctionShares(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaRealBorrowAssets) = dummyLTV.previewLowLevelRebalanceShares(0);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets) = dummyLTV.executeLowLevelRebalanceShares(0);

        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionCollateral(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) = dummyLTV.previewLowLevelRebalanceCollateral(-4000);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateral(-4000);

        assertEq(deltaShares, 0);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionCollateralHint(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) = ILTV(address(dummyLTV)).previewLowLevelRebalanceCollateralHint(-4000, true);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = ILTV(address(dummyLTV)).executeLowLevelRebalanceCollateralHint(-4000, true);

        assertEq(deltaShares, 0);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionBorrow(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) = dummyLTV.previewLowLevelRebalanceBorrow(-7500);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrow(-7500);

        assertEq(deltaShares, 0);
        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
    }

    function test_lowLevelNegativeAuctionBorrowHint(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000) {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) = ILTV(address(dummyLTV)).previewLowLevelRebalanceBorrowHint(-7500, true);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrowHint(-7500, true);

        assertEq(deltaShares, 0);
        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
    }

    function test_lowLevelPositiveAuctionShares(address owner, address user) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaRealBorrowAssets) = dummyLTV.previewLowLevelRebalanceShares(1000 * 100);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets) = dummyLTV.executeLowLevelRebalanceShares(1000 * 100);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelPositiveAuctionBorrow(address owner, address user) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        replaceImplementation();
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) = dummyLTV.previewLowLevelRebalanceBorrow(14500);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrow(14500);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaShares, 1000 * 100);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionBorrowHint(address owner, address user) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        replaceImplementation();
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) = ILTV(address(dummyLTV)).previewLowLevelRebalanceBorrowHint(14500, true);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrowHint(14500, true);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaShares, 1000 * 100);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionCollateral(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) = dummyLTV.previewLowLevelRebalanceCollateral(7500);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateral(7500);

        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(deltaShares, 1000 * 100);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionCollateralHint(
        address owner,
        address user
    ) public initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000) {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) = ILTV(address(dummyLTV)).previewLowLevelRebalanceCollateralHint(7500, true);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateralHint(7500, true);

        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(deltaShares, 1000 * 100);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_maxGrowthFee(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 18, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        // multiplied total assets by 2
        oracle.setAssetPrice(address(collateralToken), 250 * 10 ** 18);

        // check that price grown not for 100% but for 80%.
        assertEq(dummyLTV.convertToAssets(10 ** 20), 18 * 10 ** 17);
        vm.startPrank(user);
        borrowToken.approve(address(dummyLTV), 1000);
        dummyLTV.deposit(1000, user);
        assertEq(dummyLTV.convertToAssets(10 ** 20), 18 * 10 ** 17);
    }

    function test_maxDepositFinalBorder(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxDeposit(user), 10 ** 6);
    }

    function test_maxMintFinalBorder(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxMint(user), dummyLTV.previewDeposit(10 ** 6));
    }

    function test_maxDepositCollateralFinalBorder(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxDepositCollateral(user), 5 * 10 ** 5);
    }

    function test_maxMintCollateralFinalBorder(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxMintCollateral(user), dummyLTV.previewDepositCollateral(5 * 10 ** 5));
    }

    function test_leave_lending(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        deal(address(borrowToken), address(owner), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.deleverageAndWithdraw(dummyLTV.getRealBorrowAssets(), 5 * 10 ** 15);

        // total assets were reduced for 6% according to target LTV = 3/4 and 2% fee for deleverage
        assertEq(dummyLTV.totalAssets(), 985 * 10 ** 15 + 1);
        console.log('total assets collateral', dummyLTV.totalAssetsCollateral());
        console.log('Another metrics:       ', dummyLTV.getRealCollateralAssets());

        assertEq(dummyLTV.withdrawCollateral(985 * 10 ** 14, address(owner), address(owner)), 2 * 10 ** 19 + 20);
        dummyLTV.redeemCollateral(2 * 10 ** 19, address(owner), address(owner));
    }

    function test_whitelist(address owner, address user, address randUser) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.assume(user != randUser);
        vm.stopPrank();
        vm.startPrank(owner);
        deal(address(borrowToken), randUser, type(uint112).max);

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(owner);
        dummyLTV.setWhitelistRegistry(whitelistRegistry);

        dummyLTV.setIsWhitelistActivated(true);
        whitelistRegistry.addAddressToWhitelist(randUser);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(State.ReceiverNotWhitelisted.selector, user));
        dummyLTV.deposit(10 ** 17, user);

        vm.startPrank(randUser);
        borrowToken.approve(address(dummyLTV), 10 ** 17);
        dummyLTV.deposit(10 ** 17, randUser);
    }

    function test_governor(
        address ltvOwner,
        address user,
        address owner,
        address payloadsManager,
        address guardian,
        uint32 delay
    ) public initializeBalancedTest(ltvOwner, user, 10 ** 17, 0, 0, 0) {
        vm.assume(ltvOwner != address(0));
        vm.assume(owner != address(0));
        vm.assume(user != payloadsManager);
        vm.assume(delay != 0);
        vm.assume(user != owner);
        vm.assume(user != guardian);

        vm.stopPrank();
        vm.startPrank(ltvOwner);

        Timelock controller = new Timelock(owner, guardian, payloadsManager, delay);

        dummyLTV.updateGovernor(address(controller));

        vm.startPrank(user);
        
        bytes[] memory actions = new bytes[](1);
        actions[0] = abi.encodeCall(dummyLTV.setTargetLTV, (6 * 10**17));

        vm.expectRevert(abi.encodeWithSelector(IWithPayloadsManager.OnlyPayloadsManagerOrOwnerInvalidCaller.selector, user));
        controller.createPayload(address(dummyLTV), new bytes[](0));

        vm.startPrank(payloadsManager);
        uint40 payloadId = controller.createPayload(address(dummyLTV), actions);

        vm.startPrank(user);
        vm.expectPartialRevert(TimelockCommon.DelayNotPassed.selector);
        controller.executePayload(payloadId);

        vm.expectPartialRevert(IWithGuardian.OnlyGuardianOrOwnerInvalidCaller.selector);
        controller.cancelPayload(payloadId);

        vm.startPrank(guardian);
        controller.cancelPayload(payloadId);
        require(controller.getPayload(payloadId).state == PayloadState.Cancelled);
        
        vm.startPrank(payloadsManager);
        payloadId = controller.createPayload(address(dummyLTV), actions);
        vm.warp(block.timestamp + delay + 1);

        vm.startPrank(user);
        controller.executePayload(payloadId);

        require(dummyLTV.targetLTV() == 6 * 10**17);
    }

    function test_maxLowLevelRebalanceCollateral(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10**18 * 100 + 10**8);
        assertEq(dummyLTV.maxLowLevelRebalanceCollateral(), 2 * 10**6);
    }

    function test_maxLowLevelRebalanceBorrow(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10**18 * 100 + 10**8);
        assertEq(dummyLTV.maxLowLevelRebalanceBorrow(), 3 * 10**6);
    }

    function test_maxLowLevelRebalanceShares(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLTV.setMaxTotalAssetsInUnderlying(10**18 * 100 + 10**8);
        assertEq(dummyLTV.maxLowLevelRebalanceShares(), 10**8);
    }

    function test_setTargetLTV(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        uint128 newValue = 7 * 10**17;
        address governor = ILTV(address(dummyLTV)).governor();
        
        vm.startPrank(governor);
        dummyLTV.setTargetLTV(newValue);
        assertEq(dummyLTV.targetLTV(), newValue);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setTargetLTV(newValue);
        
        // Should revert if outside bounds
        vm.startPrank(governor);
        uint128 tooHighValue = dummyLTV.maxSafeLTV() + 1;
        vm.expectRevert();
        dummyLTV.setTargetLTV(tooHighValue);
        
        uint128 tooLowValue = dummyLTV.minProfitLTV() - 1;
        vm.expectRevert();
        dummyLTV.setTargetLTV(tooLowValue);
    }

    function test_setMaxSafeLTV(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        uint128 newValue = 95 * 10**16;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        dummyLTV.setMaxSafeLTV(newValue);
        assertEq(dummyLTV.maxSafeLTV(), newValue);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setMaxSafeLTV(newValue);
        
        // Should revert if below target
        vm.startPrank(governor);
        uint128 tooLowValue = dummyLTV.targetLTV() - 1;
        vm.expectRevert();
        dummyLTV.setMaxSafeLTV(tooLowValue);
    }

    function test_setMinProfitLTV(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        uint128 newValue = 6 * 10**17;
        address governor = ILTV(address(dummyLTV)).governor();

        vm.startPrank(governor);
        dummyLTV.setMinProfitLTV(newValue);
        assertEq(dummyLTV.minProfitLTV(), newValue);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setMinProfitLTV(newValue);
        
        // Should revert if above target
        vm.startPrank(governor);
        uint128 tooHighValue = dummyLTV.targetLTV() + 1;
        vm.expectRevert();
        dummyLTV.setMinProfitLTV(tooHighValue);
    }

    function test_setFeeCollector(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address newCollector = address(0x1234);
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        dummyLTV.setFeeCollector(newCollector);
        assertEq(dummyLTV.feeCollector(), newCollector);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setFeeCollector(newCollector);
    }
    
    function test_setMaxTotalAssetsInUnderlying(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        uint256 newValue = 1000000 * 10**18;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        dummyLTV.setMaxTotalAssetsInUnderlying(newValue);
        assertEq(dummyLTV.maxTotalAssetsInUnderlying(), newValue);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setMaxTotalAssetsInUnderlying(newValue);
    }
    
    function test_setMaxDeleverageFee(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        uint256 newValue = 1 * 10**17;  // 10%
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        dummyLTV.setMaxDeleverageFee(newValue);
        assertEq(dummyLTV.maxDeleverageFee(), newValue);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setMaxDeleverageFee(newValue);
        
        // Should revert if too high
        vm.startPrank(governor);
        uint256 tooHighValue = 10**18; // 100%
        vm.expectRevert();
        dummyLTV.setMaxDeleverageFee(tooHighValue);
    }
    
    function test_setIsWhitelistActivated(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        dummyLTV.setIsWhitelistActivated(true);
        assertEq(dummyLTV.isWhitelistActivated(), true);
        
        dummyLTV.setIsWhitelistActivated(false);
        assertEq(dummyLTV.isWhitelistActivated(), false);
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setIsWhitelistActivated(true);
    }
    
    function test_setWhitelistRegistry(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        WhitelistRegistry registry = new WhitelistRegistry(owner);
        
        dummyLTV.setWhitelistRegistry(registry);
        assertEq(address(dummyLTV.whitelistRegistry()), address(registry));
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setWhitelistRegistry(IWhitelistRegistry(address(0)));
    }
    
    function test_setSlippageProvider(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        ConstantSlippageProvider provider = new ConstantSlippageProvider(0, 0, owner);
        
        dummyLTV.setSlippageProvider(provider);
        assertEq(address(dummyLTV.slippageProvider()), address(provider));
        
        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setSlippageProvider(ISlippageProvider(address(0)));
    }
    
    function test_allowDisableFunctions(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.startPrank(guardian);
        
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = dummyLTV.deposit.selector;
        
        dummyLTV.allowDisableFunctions(signatures, true);
        assertTrue(dummyLTV._isFunctionDisabled(signatures[0]));
        
        dummyLTV.allowDisableFunctions(signatures, false);
        assertFalse(dummyLTV._isFunctionDisabled(signatures[0]));
        
        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.allowDisableFunctions(signatures, true);
    }
    
    function test_setIsDepositDisabled(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.startPrank(guardian);
        
        dummyLTV.setIsDepositDisabled(true);
        assertTrue(dummyLTV.isDepositDisabled());
        
        dummyLTV.setIsDepositDisabled(false);
        assertFalse(dummyLTV.isDepositDisabled());
        
        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setIsDepositDisabled(true);
    }
    
    function test_setIsWithdrawDisabled(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.startPrank(guardian);
        
        dummyLTV.setIsWithdrawDisabled(true);
        assertTrue(dummyLTV.isWithdrawDisabled());
        
        dummyLTV.setIsWithdrawDisabled(false);
        assertFalse(dummyLTV.isWithdrawDisabled());
        
        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setIsWithdrawDisabled(true);
    }
    
    function test_setLendingConnector(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address mockConnector = address(0x9876);
        
        dummyLTV.setLendingConnector(ILendingConnector(mockConnector));
        assertEq(address(ILTV(address(dummyLTV)).lendingConnector()), mockConnector);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setLendingConnector(ILendingConnector(address(0)));
    }
    
    function test_setOracleConnector(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address mockConnector = address(0x9876);
        
        dummyLTV.setOracleConnector(IOracleConnector(mockConnector));
        assertEq(address(dummyLTV.oracleConnector()), mockConnector);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.setOracleConnector(IOracleConnector(address(0)));
    }
    
    function test_updateEmergencyDeleverager(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address newDeleverager = address(0x5678);
        
        dummyLTV.updateEmergencyDeleverager(newDeleverager);
        assertEq(dummyLTV.emergencyDeleverager(), newDeleverager);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        dummyLTV.updateEmergencyDeleverager(address(0));
    }
    
    function test_updateOwner(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address newOwner = address(0x5678);
        
        ILTV(address(dummyLTV)).updateOwner(newOwner);
        assertEq(ILTV(address(dummyLTV)).owner(), newOwner);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        ILTV(address(dummyLTV)).updateOwner(address(0));
    }
    
    function test_updateGuardian(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address newGuardian = address(0x5678);
        
        ILTV(address(dummyLTV)).updateGuardian(newGuardian);
        assertEq(ILTV(address(dummyLTV)).guardian(), newGuardian);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        ILTV(address(dummyLTV)).updateGuardian(address(0));
    }
    
    function test_updateGovernor(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        address newGovernor = address(0x5678);
        
        ILTV(address(dummyLTV)).updateGovernor(newGovernor);
        assertEq(ILTV(address(dummyLTV)).governor(), newGovernor);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        ILTV(address(dummyLTV)).updateGovernor(address(0));
    }
    
    function test_deleverageAndWithdraw(address owner, address user) public initializeBalancedTest(owner, user, 10**17, 0, 0, 0) {
        vm.startPrank(owner);
        uint256 closeAmount = 1000;
        uint256 deleverageFee = 1 * 10**16;  // 1%
        
        vm.mockCall(
            address(ILTV(address(dummyLTV)).lendingConnector()),
            abi.encodeWithSelector(ILendingConnector.getRealCollateralAssets.selector),
            abi.encode(2000)
        );
        
        vm.mockCall(
            address(ILTV(address(dummyLTV)).lendingConnector()),
            abi.encodeWithSelector(ILendingConnector.getRealBorrowAssets.selector),
            abi.encode(1500)
        );
        
        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);
        
        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert();
        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);
        
        // Should revert if fee too high
        vm.startPrank(owner);
        uint256 tooBigFee = ILTV(address(dummyLTV)).maxDeleverageFee() + 1;
        vm.expectRevert();
        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, tooBigFee);
    }
}
