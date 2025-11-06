// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "../utils/BaseTest.t.sol";
import {IAdministrationEvents} from "../../src/events/IAdministrationEvents.sol";
import {IAdministrationErrors} from "../../src/errors/IAdministrationErrors.sol";

contract SetmaxSafeLtvTest is BaseTest {
    function test_failIfLessThantargetLtv(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newmaxSafeLtvDividend = ltv.targetLtvDividend() - 1;
        uint16 newmaxSafeLtvDivider = ltv.targetLtvDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                ltv.targetLtvDividend(),
                ltv.targetLtvDivider(),
                newmaxSafeLtvDividend,
                newmaxSafeLtvDivider,
                ltv.minProfitLtvDividend(),
                ltv.minProfitLtvDivider(),
                ltv.softLiquidationLtvDividend(),
                ltv.softLiquidationLtvDivider()
            )
        );
        ltv.setMaxSafeLtv(newmaxSafeLtvDividend, newmaxSafeLtvDivider);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newmaxSafeLtvDividend = 0;
        uint16 newmaxSafeLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedmaxSafeLtv.selector, newmaxSafeLtvDividend, newmaxSafeLtvDivider
            )
        );
        ltv.setMaxSafeLtv(newmaxSafeLtvDividend, newmaxSafeLtvDivider);
    }

    function test_passIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMaxSafeLtv(1, 1);
        assertEq(ltv.maxSafeLtvDividend(), 1);
        assertEq(ltv.maxSafeLtvDivider(), 1);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newmaxSafeLtvDividend = 42;
        uint16 newmaxSafeLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedmaxSafeLtv.selector, newmaxSafeLtvDividend, newmaxSafeLtvDivider
            )
        );
        ltv.setMaxSafeLtv(newmaxSafeLtvDividend, newmaxSafeLtvDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newmaxSafeLtvDividend = 85;
        uint16 newmaxSafeLtvDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxSafeLtvChanged(
            ltv.maxSafeLtvDividend(), ltv.maxSafeLtvDivider(), newmaxSafeLtvDividend, newmaxSafeLtvDivider
        );
        ltv.setMaxSafeLtv(newmaxSafeLtvDividend, newmaxSafeLtvDivider);

        assertEq(ltv.maxSafeLtvDividend(), newmaxSafeLtvDividend);
        assertEq(ltv.maxSafeLtvDivider(), newmaxSafeLtvDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newmaxSafeLtvDividend = ltv.maxSafeLtvDividend();
        uint16 newmaxSafeLtvDivider = ltv.maxSafeLtvDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxSafeLtv(newmaxSafeLtvDividend, newmaxSafeLtvDivider);
    }
}
