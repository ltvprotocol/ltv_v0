// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract AuctionsOpeningTest is BaseTest {
    uint256 constant STEPS = 10;

    function initBalances(address firstUser, address secondUser) public {
        deal(address(collateralToken), address(this), 100 ether);
        deal(address(borrowToken), address(this), 100 ether);

        deal(address(collateralToken), firstUser, 100 ether);
        deal(address(borrowToken), firstUser, 100 ether);

        deal(address(collateralToken), secondUser, 100 ether);
        deal(address(borrowToken), secondUser, 100 ether);
    }

    function depositAndExecuteAuction(address user) public {
        vm.startPrank(user);
        borrowToken.approve(address(ltv), 1 ether);
        ltv.deposit(1 ether, user);
        vm.stopPrank();

        int256 futureBorrow = ltv.futureBorrowAssets();
        uint256 amount = futureBorrow > 0 ? uint256(futureBorrow) : uint256(-futureBorrow);
        collateralToken.approve(address(ltv), amount);
        ltv.executeAuctionBorrow(-futureBorrow);
    }

    function initTest() public returns (address, address) {
        address firstUser = address(0x123);
        address secondUser = address(0x321);
        initBalances(firstUser, secondUser);
        depositAndExecuteAuction(firstUser);

        return (firstUser, secondUser);
    }

    // grows for borrow:

    function checkMaxWithdrawGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxWithdraw = ltv.maxWithdraw(user);
        uint256 currentMaxWithdraw;
        uint256 prevPreviewWithdraw = ltv.previewWithdraw(prevMaxWithdraw);
        uint256 currentPreviewWithdraw;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxWithdraw = ltv.maxWithdraw(user);
            assertTrue(currentMaxWithdraw > prevMaxWithdraw);

            currentPreviewWithdraw = ltv.previewWithdraw(currentMaxWithdraw);
            assertTrue(prevPreviewWithdraw == currentPreviewWithdraw);

            prevMaxWithdraw = currentMaxWithdraw;
            prevPreviewWithdraw = currentPreviewWithdraw;
        }
    }

    function test_AuctionOpeningDepositWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        borrowToken.approve(address(ltv), 1 ether);
        ltv.deposit(1 ether, secondUser);
        vm.stopPrank();

        checkMaxWithdrawGrowsDuringAuctionOpening(firstUser);
    }

    function test_AuctionOpeningMintWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        uint256 neededToMint = ltv.previewMint(1 ether);
        borrowToken.approve(address(ltv), neededToMint);
        ltv.mint(1 ether, secondUser);
        vm.stopPrank();

        checkMaxWithdrawGrowsDuringAuctionOpening(firstUser);
    }

    function checkPreviewRedeemGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxRedeem = ltv.maxRedeem(user);
        uint256 currentMaxRedeem;
        uint256 prevPreviewRedeem = ltv.previewRedeem(prevMaxRedeem);
        uint256 currentPreviewRedeem;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxRedeem = ltv.maxRedeem(user);
            assertTrue(currentMaxRedeem == prevMaxRedeem);

            currentPreviewRedeem = ltv.previewRedeem(currentMaxRedeem);
            assertTrue(currentPreviewRedeem > prevPreviewRedeem);

            prevMaxRedeem = currentMaxRedeem;
            prevPreviewRedeem = currentPreviewRedeem;
        }
    }

    function test_AuctionOpeningDepositRedeem(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        borrowToken.approve(address(ltv), 1 ether);
        ltv.deposit(1 ether, secondUser);
        vm.stopPrank();

        checkPreviewRedeemGrowsDuringAuctionOpening(firstUser);
    }

    function test_AuctionOpeningMintRedeem(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        uint256 neededToMint = ltv.previewMint(1 ether);
        borrowToken.approve(address(ltv), neededToMint);
        ltv.mint(1 ether, secondUser);
        vm.stopPrank();

        checkPreviewRedeemGrowsDuringAuctionOpening(firstUser);
    }

    function checkPreviewDepositGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxDeposit = ltv.maxDeposit(user);
        uint256 currentMaxDeposit;
        uint256 prevPreviewDeposit = ltv.previewDeposit(prevMaxDeposit);
        uint256 currentPreviewDeposit;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxDeposit = ltv.maxDeposit(user);
            assertTrue(currentMaxDeposit == prevMaxDeposit);

            currentPreviewDeposit = ltv.previewDeposit(currentMaxDeposit);
            assertTrue(currentPreviewDeposit > prevPreviewDeposit);

            prevMaxDeposit = currentMaxDeposit;
            prevPreviewDeposit = currentPreviewDeposit;
        }
    }

    function test_AuctionOpeningWithdrawDeposit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxWithdraw = ltv.maxWithdraw(firstUser);
        ltv.withdraw(maxWithdraw, firstUser, firstUser);
        vm.stopPrank();

        checkPreviewDepositGrowsDuringAuctionOpening(secondUser);
    }

    function test_AuctionOpeningRedeemDeposit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxRedeem = ltv.maxRedeem(firstUser);
        ltv.redeem(maxRedeem, firstUser, firstUser);
        vm.stopPrank();

        checkPreviewDepositGrowsDuringAuctionOpening(secondUser);
    }

    function checkMaxMintGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxMint = ltv.maxMint(user);
        uint256 currentMaxMint;
        uint256 prevPreviewMint = ltv.previewMint(prevMaxMint);
        uint256 currentPreviewMint;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxMint = ltv.maxMint(user);
            assertTrue(currentMaxMint > prevMaxMint);

            currentPreviewMint = ltv.previewMint(currentMaxMint);
            assertTrue(currentPreviewMint == prevPreviewMint);

            prevMaxMint = currentMaxMint;
            prevPreviewMint = currentPreviewMint;
        }
    }

    function test_AuctionOpeningWithdrawMint(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxWithdraw = ltv.maxWithdraw(firstUser);
        ltv.withdraw(maxWithdraw, firstUser, firstUser);
        vm.stopPrank();

        checkMaxMintGrowsDuringAuctionOpening(secondUser);
    }

    function test_AuctionOpeningRedeemMint(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxRedeem = ltv.maxRedeem(firstUser);
        ltv.redeem(maxRedeem, firstUser, firstUser);
        vm.stopPrank();

        checkMaxMintGrowsDuringAuctionOpening(secondUser);
    }

    // grows for collateral:

    function checkMaxWithdrawCollateralGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxWithdraw = ltv.maxWithdrawCollateral(user);
        uint256 currentMaxWithdraw;
        uint256 prevPreviewWithdraw = ltv.previewWithdrawCollateral(prevMaxWithdraw);
        uint256 currentPreviewWithdraw;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxWithdraw = ltv.maxWithdrawCollateral(user);
            assertTrue(currentMaxWithdraw > prevMaxWithdraw);

            currentPreviewWithdraw = ltv.previewWithdrawCollateral(currentMaxWithdraw);
            assertTrue(prevPreviewWithdraw == currentPreviewWithdraw);

            prevMaxWithdraw = currentMaxWithdraw;
            prevPreviewWithdraw = currentPreviewWithdraw;
        }
    }

    function test_AuctionOpeningDepositWithdrawCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        borrowToken.approve(address(ltv), 1 ether);
        ltv.deposit(1 ether, secondUser);
        vm.stopPrank();

        checkMaxWithdrawCollateralGrowsDuringAuctionOpening(firstUser);
    }

    function test_AuctionOpeningMintWithdrawCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        uint256 neededToMint = ltv.previewMint(1 ether);
        borrowToken.approve(address(ltv), neededToMint);
        ltv.mint(1 ether, secondUser);
        vm.stopPrank();

        checkMaxWithdrawCollateralGrowsDuringAuctionOpening(firstUser);
    }

    function checkPreviewRedeemCollateralGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxRedeem = ltv.maxRedeemCollateral(user);
        uint256 currentMaxRedeem;
        uint256 prevPreviewRedeem = ltv.previewRedeemCollateral(prevMaxRedeem);
        uint256 currentPreviewRedeem;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxRedeem = ltv.maxRedeemCollateral(user);
            assertTrue(currentMaxRedeem == prevMaxRedeem);

            currentPreviewRedeem = ltv.previewRedeemCollateral(currentMaxRedeem);
            assertTrue(currentPreviewRedeem > prevPreviewRedeem);

            prevMaxRedeem = currentMaxRedeem;
            prevPreviewRedeem = currentPreviewRedeem;
        }
    }

    function test_AuctionOpeningDepositRedeemCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        borrowToken.approve(address(ltv), 1 ether);
        ltv.deposit(1 ether, secondUser);
        vm.stopPrank();

        checkPreviewRedeemCollateralGrowsDuringAuctionOpening(firstUser);
    }

    function test_AuctionOpeningMintRedeemCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(secondUser);
        uint256 neededToMint = ltv.previewMint(1 ether);
        borrowToken.approve(address(ltv), neededToMint);
        ltv.mint(1 ether, secondUser);
        vm.stopPrank();

        checkPreviewRedeemCollateralGrowsDuringAuctionOpening(firstUser);
    }

    function checkPreviewDepositCollateralGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxDeposit = ltv.maxDepositCollateral(user);
        uint256 currentMaxDeposit;
        uint256 prevPreviewDeposit = ltv.previewDepositCollateral(prevMaxDeposit);
        uint256 currentPreviewDeposit;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxDeposit = ltv.maxDepositCollateral(user);
            assertTrue(currentMaxDeposit == prevMaxDeposit);

            currentPreviewDeposit = ltv.previewDepositCollateral(currentMaxDeposit);
            assertTrue(currentPreviewDeposit > prevPreviewDeposit);

            prevMaxDeposit = currentMaxDeposit;
            prevPreviewDeposit = currentPreviewDeposit;
        }
    }

    function test_AuctionOpeningWithdrawDepositCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxWithdraw = ltv.maxWithdraw(firstUser);
        ltv.withdraw(maxWithdraw, firstUser, firstUser);
        vm.stopPrank();

        checkPreviewDepositCollateralGrowsDuringAuctionOpening(secondUser);
    }

    function test_AuctionOpeningRedeemDepositCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxRedeem = ltv.maxRedeem(firstUser);
        ltv.redeem(maxRedeem, firstUser, firstUser);
        vm.stopPrank();

        checkPreviewDepositCollateralGrowsDuringAuctionOpening(secondUser);
    }

    function checkMaxMintCollateralGrowsDuringAuctionOpening(address user) public {
        uint256 prevMaxMint = ltv.maxMintCollateral(user);
        uint256 currentMaxMint;
        uint256 prevPreviewMint = ltv.previewMintCollateral(prevMaxMint);
        uint256 currentPreviewMint;

        for (uint256 i = 1; i <= STEPS; i++) {
            vm.roll(block.number + 1);

            currentMaxMint = ltv.maxMintCollateral(user);
            assertTrue(currentMaxMint > prevMaxMint);

            currentPreviewMint = ltv.previewMintCollateral(currentMaxMint);
            assertTrue(currentPreviewMint == prevPreviewMint);

            prevMaxMint = currentMaxMint;
            prevPreviewMint = currentPreviewMint;
        }
    }

    function test_AuctionOpeningWithdrawMintCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxWithdraw = ltv.maxWithdraw(firstUser);
        ltv.withdraw(maxWithdraw, firstUser, firstUser);
        vm.stopPrank();

        checkMaxMintCollateralGrowsDuringAuctionOpening(secondUser);
    }

    function test_AuctionOpeningRedeemMintCollateral(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (address firstUser, address secondUser) = initTest();

        vm.startPrank(firstUser);
        uint256 maxRedeem = ltv.maxRedeem(firstUser);
        ltv.redeem(maxRedeem, firstUser, firstUser);
        vm.stopPrank();

        checkMaxMintCollateralGrowsDuringAuctionOpening(secondUser);
    }
}
