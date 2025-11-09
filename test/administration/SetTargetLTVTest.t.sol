// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "../utils/BaseTest.t.sol";
import {IAdministrationEvents} from "../../src/events/IAdministrationEvents.sol";
import {IAdministrationErrors} from "../../src/errors/IAdministrationErrors.sol";

contract SettargetLtvTest is BaseTest {
    function test_failIfLessThanMinProfit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLtvDividend = ltv.minProfitLtvDividend() - 1;
        uint16 targetLtvDivider = ltv.minProfitLtvDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                targetLtvDividend,
                targetLtvDivider,
                ltv.maxSafeLtvDividend(),
                ltv.maxSafeLtvDivider(),
                ltv.minProfitLtvDividend(),
                ltv.minProfitLtvDivider(),
                ltv.softLiquidationLtvDividend(),
                ltv.softLiquidationLtvDivider()
            )
        );
        ltv.setTargetLtv(targetLtvDividend, targetLtvDivider);
    }

    function test_failIfGreaterThanMaxSafe(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLtvDividend = ltv.maxSafeLtvDividend() + 1;
        uint16 targetLtvDivider = ltv.maxSafeLtvDivider() + 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                targetLtvDividend,
                targetLtvDivider,
                ltv.maxSafeLtvDividend(),
                ltv.maxSafeLtvDivider(),
                ltv.minProfitLtvDividend(),
                ltv.minProfitLtvDivider(),
                ltv.softLiquidationLtvDividend(),
                ltv.softLiquidationLtvDivider()
            )
        );
        ltv.setTargetLtv(targetLtvDividend, targetLtvDivider);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLtv(0, 1);
        ltv.setTargetLtv(0, 1);
        assertEq(ltv.targetLtvDividend(), 0);
        assertEq(ltv.targetLtvDivider(), 1);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 targetLtvDividend = 1;
        uint16 targetLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedtargetLtv.selector, targetLtvDividend, targetLtvDivider
            )
        );
        ltv.setTargetLtv(targetLtvDividend, targetLtvDivider);
    }

    function test_failIfFortyTwo(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLtvDividend = 42;
        uint16 targetLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedtargetLtv.selector, targetLtvDividend, targetLtvDivider
            )
        );
        ltv.setTargetLtv(targetLtvDividend, targetLtvDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 targetLtvDividend = 74;
        uint16 targetLtvDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.TargetLtvChanged(
            ltv.targetLtvDividend(), ltv.targetLtvDivider(), targetLtvDividend, targetLtvDivider
        );
        ltv.setTargetLtv(targetLtvDividend, targetLtvDivider);

        assertEq(ltv.targetLtvDividend(), targetLtvDividend);
        assertEq(ltv.targetLtvDivider(), targetLtvDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newtargetLtvDividend = ltv.targetLtvDividend();
        uint16 newtargetLtvDivider = ltv.targetLtvDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setTargetLtv(newtargetLtvDividend, newtargetLtvDivider);
    }
}
