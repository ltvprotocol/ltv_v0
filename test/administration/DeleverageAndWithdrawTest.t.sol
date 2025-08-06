// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PrepareEachFunctionSuccessfulExecution.sol";
import "../../src/errors/IAuctionErrors.sol";
import "../../src/errors/ILowLevelRebalanceErrors.sol";
import "../../src/errors/IVaultErrors.sol";
import "../../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";

contract DeleverageAndWithdrawTest is PrepareEachFunctionSuccessfulExecution {
    function test_normalData(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 100);

        // equivalent to 30 * 10**17 borrow assets + 1% fee
        uint256 expectedBalance = 15 * 10 ** 17 + 5 * 10 ** 15;
        assertEq(collateralToken.balanceOf(data.emergencyDeleverager), expectedBalance);
        assertEq(ltv.futureBorrowAssets(), 0);
        assertEq(ltv.futureCollateralAssets(), 0);
        assertEq(ltv.futureRewardBorrowAssets(), 0);
        assertEq(ltv.futureRewardCollateralAssets(), 0);
        assertEq(ltv.getLendingConnector().getRealBorrowAssets(false, ""), 0);
        assertEq(ltv.lendingConnector().getRealCollateralAssets(false, ""), 0);
        assertEq(ltv.lendingConnector().getRealBorrowAssets(false, ""), 0);

        assertEq(ltv.isVaultDeleveraged(), true);
        assertEq(address(ltv.getLendingConnector()), address(ltv.vaultBalanceAsLendingConnector()));
    }

    function test_getEverythingAsFee(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        vm.prank(data.governor);
        ltv.setMaxDeleverageFee(1, 1); // 100% fee

        uint256 collateralAssets = ltv.getLendingConnector().getRealCollateralAssets(false, "");
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 1);

        assertEq(collateralToken.balanceOf(data.emergencyDeleverager), collateralAssets);
    }

    function test_failIfGreaterThanMaxDeleverageFee(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        uint16 maxDeleverageFeeDividend = ltv.maxDeleverageFeeDividend();
        uint16 maxDeleverageFeeDivider = ltv.maxDeleverageFeeDivider();
        uint16 tooHighDividend = maxDeleverageFeeDividend + 1; // This will exceed max
        vm.startPrank(data.emergencyDeleverager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.ExceedsMaxDeleverageFee.selector,
                tooHighDividend,
                maxDeleverageFeeDivider,
                maxDeleverageFeeDividend,
                maxDeleverageFeeDivider
            )
        );
        ltv.deleverageAndWithdraw(0, tooHighDividend, maxDeleverageFeeDivider);
    }

    function test_successfulMoneyWithdrawal(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != address(0));
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");
        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        vm.startPrank(address(0));
        ltv.transfer(address(user), ltv.balanceOf(address(0)));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 shares = ltv.withdrawCollateral(10 ** 10, address(user), address(user));

        assertEq(shares, 2 * 10 ** 10);
    }

    function test_lendingFullyWithdrawed(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");
        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        assertEq(ltv.lendingConnector().getRealBorrowAssets(false, ""), 0);
        assertEq(ltv.lendingConnector().getRealCollateralAssets(false, ""), 0);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_auctionNotAvailable(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 100);

        int256 amount = 10 ** 10;
        vm.expectRevert(
            abi.encodeWithSelector(IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector, 0, 0, amount)
        );
        ltv.executeAuctionBorrow(amount);

        vm.expectRevert(
            abi.encodeWithSelector(IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector, 0, 0, -amount)
        );
        ltv.executeAuctionBorrow(-amount);

        vm.expectRevert(
            abi.encodeWithSelector(IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector, 0, 0, amount)
        );
        ltv.executeAuctionCollateral(amount);

        vm.expectRevert(
            abi.encodeWithSelector(IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector, 0, 0, -amount)
        );
        ltv.executeAuctionCollateral(-amount);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_lowLevelBorrowNotAvailable(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 100);

        assertEq(ltv.maxLowLevelRebalanceBorrow(), 0);

        int256 amount = 10 ** 10;
        vm.expectRevert(abi.encodeWithSelector(ILowLevelRebalanceErrors.ZeroTargetLTVDisablesBorrow.selector));
        ltv.executeLowLevelRebalanceBorrow(-amount);

        vm.expectRevert(
            abi.encodeWithSelector(ILowLevelRebalanceErrors.ExceedsLowLevelRebalanceMaxDeltaBorrow.selector, amount, 0)
        );
        ltv.executeLowLevelRebalanceBorrowHint(amount, true);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_lowLevelRebalanceCollateral(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        int256 amount = 10 ** 10;

        // Fail for cases where trying to deposit
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(VaultBalanceAsLendingConnector.UnexpectedSupplyCall.selector));
        ltv.executeLowLevelRebalanceCollateral(amount);

        vm.expectRevert(abi.encodeWithSelector(VaultBalanceAsLendingConnector.UnexpectedSupplyCall.selector));
        ltv.executeLowLevelRebalanceCollateralHint(amount, true);

        // Work like withdrawCollateral if trying to withdraw
        (int256 deltaRealBorrowAssets, int256 deltaShares) = ltv.executeLowLevelRebalanceCollateral(-amount);
        assertEq(deltaRealBorrowAssets, 0);
        assertEq(deltaShares, -amount * 2);

        (deltaRealBorrowAssets, deltaShares) = ltv.executeLowLevelRebalanceCollateralHint(-amount, false);
        assertEq(deltaRealBorrowAssets, 0);
        assertEq(deltaShares, -amount * 2);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_lowLevelRebalanceShares(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        int256 amount = 10 ** 10;

        // Fail for cases where trying to deposit
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(VaultBalanceAsLendingConnector.UnexpectedSupplyCall.selector));
        ltv.executeLowLevelRebalanceShares(amount);

        // Work like withdrawCollateral if trying to withdraw
        (int256 deltaRealCollateral, int256 deltaRealBorrow) = ltv.executeLowLevelRebalanceShares(-amount);
        assertEq(deltaRealCollateral, -amount / 2);
        assertEq(deltaRealBorrow, 0);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_vaultFunctions(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(VaultBalanceAsLendingConnector.UnexpectedSupplyCall.selector));
        uint256 amount = 10 ** 10;
        ltv.depositCollateral(amount, address(user));

        vm.expectRevert(abi.encodeWithSelector(VaultBalanceAsLendingConnector.UnexpectedBorrowCall.selector));
        ltv.withdraw(amount, address(user), address(user));

        vm.expectRevert(abi.encodeWithSelector(IVaultErrors.ExceedsMaxDeposit.selector, address(user), amount, 0));
        ltv.deposit(amount, address(user));

        assertEq(ltv.withdrawCollateral(amount, address(user), address(user)), amount * 2);
    }

    function test_getLendingConnectorChanges(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        assertEq(address(ltv.getLendingConnector()), address(ltv.lendingConnector()));

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 100);

        assertEq(address(ltv.getLendingConnector()), address(ltv.vaultBalanceAsLendingConnector()));
        assertNotEq(address(ltv.getLendingConnector()), address(ltv.lendingConnector()));
    }

    function test_isVaultDeleveragedChanged(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        assertEq(ltv.isVaultDeleveraged(), false);

        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");

        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);

        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 1, 100);

        assertEq(ltv.isVaultDeleveraged(), true);
    }

    function test_failIfVaultBalanceAsLendingConnectorIsNotSet(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.prank(data.owner);
        ltv.setVaultBalanceAsLendingConnector(address(0));
        vm.startPrank(data.emergencyDeleverager);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.VaultBalanceAsLendingConnectorNotSet.selector));
        ltv.deleverageAndWithdraw(0, 0, 1);
    }

    function test_failIfNotEnoughBorrowAssets(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");
        uint256 amount = borrowAssets - 1;
        deal(address(borrowToken), data.emergencyDeleverager, amount);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), amount);
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.ImpossibleToCoverDeleverage.selector, borrowAssets, amount)
        );
        ltv.deleverageAndWithdraw(amount, 0, 1);
    }

    function test_failIfVaultAlreadyDeleveraged(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");
        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.VaultAlreadyDeleveraged.selector));
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);
    }

    function test_maxDeleverageFeeApplied(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        uint256 borrowAssets = ltv.getLendingConnector().getRealBorrowAssets(false, "");
        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);

        assertEq(ltv.convertToAssets(10 ** 18), 10 ** 18);
        vm.prank(data.owner);
        oracle.setAssetPrice(address(collateralToken), 10 ** 18 * 10 / 4);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);
        uint256 supplyBefore = ltv.totalSupply();
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);
        assertGt(ltv.totalSupply(), supplyBefore);
    }
}
