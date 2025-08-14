// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMinProfitLTVTest is BaseTest {
    function test_failIfGreaterThanTargetLTV(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMinProfitLTVDividend = ltv.targetLTVDividend() + 1;
        uint16 newMinProfitLTVDivider = ltv.targetLTVDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                ltv.targetLTVDividend(),
                ltv.targetLTVDivider(),
                ltv.maxSafeLTVDividend(),
                ltv.maxSafeLTVDivider(),
                newMinProfitLTVDividend,
                newMinProfitLTVDivider
            )
        );
        ltv.setMinProfitLTV(newMinProfitLTVDividend, newMinProfitLTVDivider);
    }

    function test_passIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLTV(0, 1);
        assertEq(ltv.minProfitLTVDividend(), 0);
        assertEq(ltv.minProfitLTVDivider(), 1);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMinProfitLTVDividend = 1;
        uint16 newMinProfitLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedMinProfitLTV.selector, newMinProfitLTVDividend, newMinProfitLTVDivider
            )
        );
        ltv.setMinProfitLTV(newMinProfitLTVDividend, newMinProfitLTVDivider);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMinProfitLTVDividend = 42;
        uint16 newMinProfitLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedMinProfitLTV.selector, newMinProfitLTVDividend, newMinProfitLTVDivider
            )
        );
        ltv.setMinProfitLTV(newMinProfitLTVDividend, newMinProfitLTVDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMinProfitLTVDividend = 45;
        uint16 newMinProfitLTVDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MinProfitLTVChanged(
            ltv.minProfitLTVDividend(), ltv.minProfitLTVDivider(), newMinProfitLTVDividend, newMinProfitLTVDivider
        );
        ltv.setMinProfitLTV(newMinProfitLTVDividend, newMinProfitLTVDivider);

        assertEq(ltv.minProfitLTVDividend(), newMinProfitLTVDividend);
        assertEq(ltv.minProfitLTVDivider(), newMinProfitLTVDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newMinProfitLTVDividend = ltv.minProfitLTVDividend();
        uint16 newMinProfitLTVDivider = ltv.minProfitLTVDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMinProfitLTV(newMinProfitLTVDividend, newMinProfitLTVDivider);
    }
}
