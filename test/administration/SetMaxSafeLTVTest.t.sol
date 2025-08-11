// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMaxSafeLTVTest is BaseTest {
    function test_failIfLessThanTargetLTV(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMaxSafeLTVDividend = ltv.targetLTVDividend() - 1;
        uint16 newMaxSafeLTVDivider = ltv.targetLTVDivider();
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                ltv.targetLTVDividend(),
                ltv.targetLTVDivider(),
                newMaxSafeLTVDividend,
                newMaxSafeLTVDivider,
                ltv.minProfitLTVDividend(),
                ltv.minProfitLTVDivider()
            )
        );
        ltv.setMaxSafeLTV(newMaxSafeLTVDividend, newMaxSafeLTVDivider);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMaxSafeLTVDividend = 0;
        uint16 newMaxSafeLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedMaxSafeLTV.selector, newMaxSafeLTVDividend, newMaxSafeLTVDivider
            )
        );
        ltv.setMaxSafeLTV(newMaxSafeLTVDividend, newMaxSafeLTVDivider);
    }

    function test_passIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMaxSafeLTV(1, 1);
        assertEq(ltv.maxSafeLTVDividend(), 1);
        assertEq(ltv.maxSafeLTVDivider(), 1);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMaxSafeLTVDividend = 42;
        uint16 newMaxSafeLTVDivider = 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.UnexpectedMaxSafeLTV.selector, newMaxSafeLTVDividend, newMaxSafeLTVDivider
            )
        );
        ltv.setMaxSafeLTV(newMaxSafeLTVDividend, newMaxSafeLTVDivider);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMaxSafeLTVDividend = 85;
        uint16 newMaxSafeLTVDivider = 100;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxSafeLTVChanged(
            ltv.maxSafeLTVDividend(), ltv.maxSafeLTVDivider(), newMaxSafeLTVDividend, newMaxSafeLTVDivider
        );
        ltv.setMaxSafeLTV(newMaxSafeLTVDividend, newMaxSafeLTVDivider);

        assertEq(ltv.maxSafeLTVDividend(), newMaxSafeLTVDividend);
        assertEq(ltv.maxSafeLTVDivider(), newMaxSafeLTVDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newMaxSafeLTVDividend = ltv.maxSafeLTVDividend();
        uint16 newMaxSafeLTVDivider = ltv.maxSafeLTVDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxSafeLTV(newMaxSafeLTVDividend, newMaxSafeLTVDivider);
    }
}
