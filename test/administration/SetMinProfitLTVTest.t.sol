// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";

contract SetminProfitLtvTest is BaseTest {
    function test_failIfGreaterThantargetLtv(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newminProfitLtvDividend = ltv.targetLtvDividend() + 1;
        uint16 newminProfitLtvDivider = ltv.targetLtvDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                ltv.targetLtvDividend(),
                ltv.targetLtvDivider(),
                ltv.maxSafeLtvDividend(),
                ltv.maxSafeLtvDivider(),
                newminProfitLtvDividend,
                newminProfitLtvDivider,
                ltv.softLiquidationLtvDividend(),
                ltv.softLiquidationLtvDivider()
            )
        );
        ltv.setMinProfitLtv(newminProfitLtvDividend, newminProfitLtvDivider);
    }

    function test_passIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLtv(0, 1);
        assertEq(ltv.minProfitLtvDividend(), 0);
        assertEq(ltv.minProfitLtvDivider(), 1);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newminProfitLtvDividend = 1;
        uint16 newminProfitLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedminProfitLtv.selector, newminProfitLtvDividend, newminProfitLtvDivider
            )
        );
        ltv.setMinProfitLtv(newminProfitLtvDividend, newminProfitLtvDivider);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newminProfitLtvDividend = 42;
        uint16 newminProfitLtvDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedminProfitLtv.selector, newminProfitLtvDividend, newminProfitLtvDivider
            )
        );
        ltv.setMinProfitLtv(newminProfitLtvDividend, newminProfitLtvDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newminProfitLtvDividend = 45;
        uint16 newminProfitLtvDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MinProfitLtvChanged(
            ltv.minProfitLtvDividend(), ltv.minProfitLtvDivider(), newminProfitLtvDividend, newminProfitLtvDivider
        );
        ltv.setMinProfitLtv(newminProfitLtvDividend, newminProfitLtvDivider);

        assertEq(ltv.minProfitLtvDividend(), newminProfitLtvDividend);
        assertEq(ltv.minProfitLtvDivider(), newminProfitLtvDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newminProfitLtvDividend = ltv.minProfitLtvDividend();
        uint16 newminProfitLtvDivider = ltv.minProfitLtvDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMinProfitLtv(newminProfitLtvDividend, newminProfitLtvDivider);
    }
}
