// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMaxSafeLTVTest is BaseTest {
    function test_failIfLessThanTargetLTV(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMaxSafeLTV = ltv.targetLTV() - 1;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector, ltv.targetLTV(), newMaxSafeLTV, ltv.minProfitLTV()
            )
        );
        ltv.setMaxSafeLTV(newMaxSafeLTV);
    }

    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 newMaxSafeLTV = 0;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedMaxSafeLTV.selector, newMaxSafeLTV));
        ltv.setMaxSafeLTV(newMaxSafeLTV);
    }

    function test_passIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ltv.setMaxSafeLTV(10**18);
        assertEq(ltv.maxSafeLTV(), 10**18);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 newMaxSafeLTV = 42 * 10 ** 18;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedMaxSafeLTV.selector, newMaxSafeLTV));
        ltv.setMaxSafeLTV(newMaxSafeLTV);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMaxSafeLTV = 85 * 10 ** 16; // 0.85
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxSafeLTVChanged(ltv.maxSafeLTV(), newMaxSafeLTV);
        ltv.setMaxSafeLTV(newMaxSafeLTV);

        assertEq(ltv.maxSafeLTV(), newMaxSafeLTV);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint128 newMaxSafeLTV = ltv.maxSafeLTV();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxSafeLTV(newMaxSafeLTV);
    }
}
