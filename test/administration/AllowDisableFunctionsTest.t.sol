// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "./PrepareEachFunctionSuccessfulExecution.sol";
import "src/interfaces/ILTV.sol";
import "src/interfaces/IModules.sol";

contract AllowDisableFunctionsTest is PrepareEachFunctionSuccessfulExecution {
    function test_disableRandomSelector(DefaultTestData memory defaultData, bytes4 randomSelector)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = randomSelector;

        vm.startPrank(defaultData.guardian);
        ltv.allowDisableFunctions(signatures, true);
        assertTrue(ltv._isFunctionDisabled(randomSelector));
    }

    function test_disableSpecificFunction(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = ltv.deposit.selector;

        vm.startPrank(defaultData.guardian);
        ltv.allowDisableFunctions(signatures, true);
        assertTrue(ltv._isFunctionDisabled(ltv.deposit.selector));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.FunctionStopped.selector, ltv.deposit.selector));
        ltv.deposit(100, user);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_batchDisableAllFunctions(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        (bytes[] memory calls, bytes4[] memory selectors, address[] memory callers) =
            functionsCanBeDisabled(defaultData, user);
        vm.prank(defaultData.guardian);
        ltv.allowDisableFunctions(selectors, true);

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(callers[i]);
            (bool success, bytes memory data) = address(ltv).call(calls[i]);
            assertFalse(success);
            assertEq(data, abi.encodeWithSelector(IAdministrationErrors.FunctionStopped.selector, selectors[i]));
        }
    }

    /// forge-config: default.fuzz.runs = 8
    function test_batchEnableFunctions(DefaultTestData memory defaultData, address user) public {
        (bytes[] memory calls, bytes4[] memory selectors, address[] memory callers) =
            functionsCanBeDisabled(defaultData, user);

        for (uint256 i = 0; i < calls.length; i++) {
            bytes4[] memory selector = new bytes4[](1);
            selector[0] = selectors[i];
            passDisableEnableFunction(defaultData, callers[i], calls[i], selector);
        }
    }

    function passDisableEnableFunction(
        DefaultTestData memory defaultData,
        address caller,
        bytes memory call,
        bytes4[] memory selector
    ) public testWithPredefinedDefaultValues(defaultData) {
        prepareEachFunctionSuccessfulExecution(caller);

        vm.prank(defaultData.guardian);
        ltv.allowDisableFunctions(selector, true);
        vm.prank(caller);
        (bool success, bytes memory data) = address(ltv).call(call);
        assertFalse(success);
        assertEq(data, abi.encodeWithSelector(IAdministrationErrors.FunctionStopped.selector, selector[0]));

        vm.prank(defaultData.guardian);
        ltv.allowDisableFunctions(selector, false);
        vm.prank(caller);
        (success,) = address(ltv).call(call);
        assertTrue(success);
    }

    function test_ownerCannotExecuteDisabledFunction(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = ltv.deposit.selector;

        vm.startPrank(defaultData.guardian);
        ltv.allowDisableFunctions(signatures, true);

        vm.startPrank(defaultData.owner);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.FunctionStopped.selector, ltv.deposit.selector));
        ltv.deposit(100, defaultData.owner);
    }

    function test_governorCannotExecuteDisabledFunction(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = ltv.deposit.selector;

        vm.startPrank(defaultData.guardian);
        ltv.allowDisableFunctions(signatures, true);

        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.FunctionStopped.selector, ltv.deposit.selector));
        ltv.deposit(100, defaultData.governor);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_functionsCannotBeDisabled(DefaultTestData memory defaultData) public {
        (bytes[] memory calls, bytes4[] memory selectors, address[] memory callers) =
            functionsCannotBeDisabled(defaultData);
        for (uint256 i = 0; i < calls.length; i++) {
            passDisabledFunction(defaultData, callers[i], calls[i], selectors);
        }
    }

    function passDisabledFunction(
        DefaultTestData memory defaultData,
        address caller,
        bytes memory call,
        bytes4[] memory allSelectors
    ) public testWithPredefinedDefaultValues(defaultData) {
        prepareEachFunctionSuccessfulExecution(caller);

        vm.prank(defaultData.guardian);
        ltv.allowDisableFunctions(allSelectors, true);
        vm.prank(caller);
        (bool success,) = address(ltv).call(call);
        assertTrue(success);
    }

    function functionsCannotBeDisabled(DefaultTestData memory defaultData)
        public
        pure
        returns (bytes[] memory, bytes4[] memory, address[] memory)
    {
        bytes[] memory calls = new bytes[](12);
        bytes4[] memory selectors = new bytes4[](12);
        address[] memory callers = new address[](12);

        // Core functions that cannot be disabled
        calls[0] = abi.encodeCall(ILTV.allowDisableFunctions, (new bytes4[](1), true));
        selectors[0] = ILTV.allowDisableFunctions.selector;
        callers[0] = defaultData.guardian;

        calls[1] = abi.encodeCall(ILTV.deleverageAndWithdraw, (type(uint112).max, uint16(1), uint16(50))); // 2% fee
        selectors[1] = ILTV.deleverageAndWithdraw.selector;
        callers[1] = defaultData.emergencyDeleverager;

        // Ownership functions
        calls[2] = abi.encodeCall(ILTV.renounceOwnership, ());
        selectors[2] = ILTV.renounceOwnership.selector;
        callers[2] = defaultData.owner;

        calls[3] = abi.encodeCall(ILTV.setModules, (IModules(address(1))));
        selectors[3] = ILTV.setModules.selector;
        callers[3] = defaultData.owner;

        // Update functions
        calls[4] = abi.encodeCall(ILTV.updateGuardian, defaultData.guardian);
        selectors[4] = ILTV.updateGuardian.selector;
        callers[4] = defaultData.owner;

        calls[5] = abi.encodeCall(ILTV.updateGovernor, defaultData.governor);
        selectors[5] = ILTV.updateGovernor.selector;
        callers[5] = defaultData.owner;

        calls[6] = abi.encodeCall(ILTV.updateEmergencyDeleverager, defaultData.emergencyDeleverager);
        selectors[6] = ILTV.updateEmergencyDeleverager.selector;
        callers[6] = defaultData.owner;

        calls[7] = abi.encodeCall(ILTV.setIsDepositDisabled, (false));
        selectors[7] = ILTV.setIsDepositDisabled.selector;
        callers[7] = defaultData.guardian;

        calls[8] = abi.encodeCall(ILTV.setIsWithdrawDisabled, (false));
        selectors[8] = ILTV.setIsWithdrawDisabled.selector;
        callers[8] = defaultData.guardian;

        calls[9] = abi.encodeCall(ILTV.setLendingConnector, address(1));
        selectors[9] = ILTV.setLendingConnector.selector;
        callers[9] = defaultData.owner;

        calls[10] = abi.encodeCall(ILTV.setOracleConnector, address(1));
        selectors[10] = ILTV.setOracleConnector.selector;
        callers[10] = defaultData.owner;

        calls[11] = abi.encodeCall(ILTV.transferOwnership, (defaultData.owner));
        selectors[11] = ILTV.transferOwnership.selector;
        callers[11] = defaultData.owner;

        return (calls, selectors, callers);
    }

    function functionsCanBeDisabled(DefaultTestData memory defaultData, address user)
        public
        pure
        returns (bytes[] memory, bytes4[] memory, address[] memory)
    {
        bytes[] memory calls = new bytes[](28);
        bytes4[] memory selectors = new bytes4[](28);
        address[] memory callers = new address[](28);
        uint256 amount = 1000;

        // Core functions
        calls[0] = abi.encodeCall(ILTV.approve, (user, amount));
        selectors[0] = ILTV.approve.selector;
        callers[0] = user;

        calls[1] = abi.encodeCall(ILTV.mint, (amount, user));
        selectors[1] = ILTV.mint.selector;
        callers[1] = user;

        calls[2] = abi.encodeCall(ILTV.redeem, (amount, user, user));
        selectors[2] = ILTV.redeem.selector;
        callers[2] = user;

        calls[3] = abi.encodeCall(ILTV.withdraw, (amount, user, user));
        selectors[3] = ILTV.withdraw.selector;
        callers[3] = user;

        calls[4] = abi.encodeCall(ILTV.deposit, (amount, user));
        selectors[4] = ILTV.deposit.selector;
        callers[4] = user;

        calls[5] = abi.encodeCall(ILTV.depositCollateral, (amount, user));
        selectors[5] = ILTV.depositCollateral.selector;
        callers[5] = user;

        calls[6] = abi.encodeCall(ILTV.mintCollateral, (amount, user));
        selectors[6] = ILTV.mintCollateral.selector;
        callers[6] = user;

        calls[7] = abi.encodeCall(ILTV.redeemCollateral, (amount, user, user));
        selectors[7] = ILTV.redeemCollateral.selector;
        callers[7] = user;

        calls[8] = abi.encodeCall(ILTV.withdrawCollateral, (amount, user, user));
        selectors[8] = ILTV.withdrawCollateral.selector;
        callers[8] = user;

        // Transfer functions
        calls[9] = abi.encodeCall(ILTV.transfer, (user, amount));
        selectors[9] = ILTV.transfer.selector;
        callers[9] = user;

        calls[10] = abi.encodeCall(ILTV.transferFrom, (address(0), user, amount));
        selectors[10] = ILTV.transferFrom.selector;
        callers[10] = user;

        // Auction functions
        calls[11] = abi.encodeCall(ILTV.executeAuctionBorrow, (int256(amount)));
        selectors[11] = ILTV.executeAuctionBorrow.selector;
        callers[11] = user;

        calls[12] = abi.encodeCall(ILTV.executeAuctionCollateral, (int256(amount)));
        selectors[12] = ILTV.executeAuctionCollateral.selector;
        callers[12] = user;

        // Rebalance functions
        calls[13] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (int256(amount)));
        selectors[13] = ILTV.executeLowLevelRebalanceBorrow.selector;
        callers[13] = user;

        calls[14] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (int256(amount), true));
        selectors[14] = ILTV.executeLowLevelRebalanceBorrowHint.selector;
        callers[14] = user;

        calls[15] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (int256(amount)));
        selectors[15] = ILTV.executeLowLevelRebalanceCollateral.selector;
        callers[15] = user;

        calls[16] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (int256(amount), true));
        selectors[16] = ILTV.executeLowLevelRebalanceCollateralHint.selector;
        callers[16] = user;

        calls[17] = abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (int256(amount)));
        selectors[17] = ILTV.executeLowLevelRebalanceShares.selector;
        callers[17] = user;

        // Setting functions
        calls[18] = abi.encodeCall(ILTV.setFeeCollector, address(1));
        selectors[18] = ILTV.setFeeCollector.selector;
        callers[18] = defaultData.governor;

        calls[19] = abi.encodeCall(ILTV.setIsWhitelistActivated, (false));
        selectors[19] = ILTV.setIsWhitelistActivated.selector;
        callers[19] = defaultData.governor;

        calls[20] = abi.encodeCall(ILTV.setMaxDeleverageFee, (uint16(1), uint16(50))); // 2% fee
        selectors[20] = ILTV.setMaxDeleverageFee.selector;
        callers[20] = defaultData.governor;

        calls[21] = abi.encodeCall(ILTV.setMaxGrowthFee, (uint16(1), uint16(5)));
        selectors[21] = ILTV.setMaxGrowthFee.selector;
        callers[21] = defaultData.governor;

        calls[22] = abi.encodeCall(ILTV.setMaxSafeLTV, (9, 10));
        selectors[22] = ILTV.setMaxSafeLTV.selector;
        callers[22] = defaultData.governor;

        calls[23] = abi.encodeCall(ILTV.setMaxTotalAssetsInUnderlying, type(uint112).max);
        selectors[23] = ILTV.setMaxTotalAssetsInUnderlying.selector;
        callers[23] = defaultData.governor;

        calls[24] = abi.encodeCall(ILTV.setMinProfitLTV, (5, 10));
        selectors[24] = ILTV.setMinProfitLTV.selector;
        callers[24] = defaultData.governor;

        calls[25] = abi.encodeCall(ILTV.setSlippageProvider, address(1));
        selectors[25] = ILTV.setSlippageProvider.selector;
        callers[25] = defaultData.governor;

        calls[26] = abi.encodeCall(ILTV.setTargetLTV, (75, 100));
        selectors[26] = ILTV.setTargetLTV.selector;
        callers[26] = defaultData.governor;

        calls[27] = abi.encodeCall(ILTV.setWhitelistRegistry, address(1));
        selectors[27] = ILTV.setWhitelistRegistry.selector;
        callers[27] = defaultData.governor;

        return (calls, selectors, callers);
    }
}
