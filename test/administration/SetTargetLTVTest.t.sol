// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetTargetLTVTest is BaseTest {
    function test_failIfLessThanMinProfit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLTVDividend = ltv.minProfitLTVDividend() - 1;
        uint16 targetLTVDivider = ltv.minProfitLTVDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                targetLTVDividend,
                targetLTVDivider,
                ltv.maxSafeLTVDividend(),
                ltv.maxSafeLTVDivider(),
                ltv.minProfitLTVDividend(),
                ltv.minProfitLTVDivider()
            )
        );
        ltv.setTargetLTV(targetLTVDividend, targetLTVDivider);
    }

    function test_failIfGreaterThanMaxSafe(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLTVDividend = ltv.maxSafeLTVDividend() + 1;
        uint16 targetLTVDivider = ltv.maxSafeLTVDivider() + 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                targetLTVDividend,
                targetLTVDivider,
                ltv.maxSafeLTVDividend(),
                ltv.maxSafeLTVDivider(),
                ltv.minProfitLTVDividend(),
                ltv.minProfitLTVDivider()
            )
        );
        ltv.setTargetLTV(targetLTVDividend, targetLTVDivider);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLTV(0, 1);
        ltv.setTargetLTV(0, 1);
        assertEq(ltv.targetLTVDividend(), 0);
        assertEq(ltv.targetLTVDivider(), 1);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 targetLTVDividend = 1;
        uint16 targetLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedTargetLTV.selector, targetLTVDividend, targetLTVDivider
            )
        );
        ltv.setTargetLTV(targetLTVDividend, targetLTVDivider);
    }

    function test_failIfFortyTwo(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLTVDividend = 42;
        uint16 targetLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedTargetLTV.selector, targetLTVDividend, targetLTVDivider
            )
        );
        ltv.setTargetLTV(targetLTVDividend, targetLTVDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLTVDividend = 74;
        uint16 targetLTVDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.TargetLTVChanged(
            ltv.targetLTVDividend(), ltv.targetLTVDivider(), targetLTVDividend, targetLTVDivider
        );
        ltv.setTargetLTV(targetLTVDividend, targetLTVDivider);

        assertEq(ltv.targetLTVDividend(), targetLTVDividend);
        assertEq(ltv.targetLTVDivider(), targetLTVDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newTargetLTVDividend = ltv.targetLTVDividend();
        uint16 newTargetLTVDivider = ltv.targetLTVDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setTargetLTV(newTargetLTVDividend, newTargetLTVDivider);
    }
}
