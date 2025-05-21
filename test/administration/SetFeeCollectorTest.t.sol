// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../utils/BaseTest.t.sol';

contract SetFeeCollectorTest is BaseTest {
    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        address newFeeCollector = address(0);
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroFeeCollector.selector));
        ltv.setFeeCollector(newFeeCollector);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != defaultData.governor);
        address newFeeCollector = ltv.feeCollector();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setFeeCollector(newFeeCollector);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        address newFeeCollector = address(1);
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.FeeCollectorUpdated(ltv.feeCollector(), newFeeCollector);
        ltv.setFeeCollector(newFeeCollector);

        assertEq(ltv.feeCollector(), newFeeCollector);
    }
}