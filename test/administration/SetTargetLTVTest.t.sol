// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetTargetLTVTest is BaseTest {
    function test_failIfLessThanMinProfit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 targetLTV = ltv.minProfitLTV() - 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector, targetLTV, ltv.maxSafeLTV(), ltv.minProfitLTV()
            )
        );
        ltv.setTargetLTV(targetLTV);
    }

    function test_failIfGreaterThanMaxSafe(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 targetLTV = ltv.maxSafeLTV() + 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector, targetLTV, ltv.maxSafeLTV(), ltv.minProfitLTV()
            )
        );
        ltv.setTargetLTV(targetLTV);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLTV(0);
        ltv.setTargetLTV(0);
        assertEq(ltv.targetLTV(), 0);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 targetLTV = 1 * 10 ** 18;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedTargetLTV.selector, targetLTV));
        ltv.setTargetLTV(targetLTV);
    }

    function test_failIfFortyTwo(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 targetLTV = 42 * 10 ** 18;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedTargetLTV.selector, targetLTV));
        ltv.setTargetLTV(targetLTV);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 targetLTV = 74 * 10 ** 16;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.TargetLTVChanged(ltv.targetLTV(), targetLTV);
        ltv.setTargetLTV(targetLTV);

        assertEq(ltv.targetLTV(), targetLTV);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint128 newTargetLTV = ltv.targetLTV();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setTargetLTV(newTargetLTV);
    }
}
