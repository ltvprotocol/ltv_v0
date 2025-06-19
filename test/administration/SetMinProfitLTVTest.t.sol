// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMinProfitLTVTest is BaseTest {
    function test_failIfGreaterThanTargetLTV(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMinProfitLTV = ltv.targetLTV() + 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector, ltv.targetLTV(), ltv.maxSafeLTV(), newMinProfitLTV
            )
        );
        ltv.setMinProfitLTV(newMinProfitLTV);
    }

    function test_passIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMinProfitLTV(0);
        assertEq(ltv.minProfitLTV(), 0);
    }

    function test_failIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 newMinProfitLTV = 1 * 10 ** 18; // 1.0
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedMinProfitLTV.selector, newMinProfitLTV));
        ltv.setMinProfitLTV(newMinProfitLTV);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 newMinProfitLTV = 42 * 10 ** 18;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedMinProfitLTV.selector, newMinProfitLTV));
        ltv.setMinProfitLTV(newMinProfitLTV);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMinProfitLTV = 45 * 10 ** 16; // 0.45
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MinProfitLTVChanged(ltv.minProfitLTV(), newMinProfitLTV);
        ltv.setMinProfitLTV(newMinProfitLTV);

        assertEq(ltv.minProfitLTV(), newMinProfitLTV);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint128 newMinProfitLTV = ltv.minProfitLTV();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMinProfitLTV(newMinProfitLTV);
    }
}
