// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMaxTotalAssetsInUnderlyingTest is BaseTest {
    function test_maxMintChanged(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint256 expectedMaxMint = 5 * 10 ** 17;

        assertGt(ltv.maxMint(address(0)), expectedMaxMint);
        uint256 newMaxTotalAssetsInUnderlying = 10 ** 18 + expectedMaxMint;
        vm.startPrank(defaultData.governor);
        ltv.setMaxTotalAssetsInUnderlying(newMaxTotalAssetsInUnderlying);

        assertEq(ltv.maxMint(address(0)), expectedMaxMint);
    }

    function test_zero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        assertGt(ltv.maxMint(address(0)), 0);
        vm.startPrank(defaultData.governor);
        ltv.setMaxTotalAssetsInUnderlying(0);
        assertEq(ltv.maxMint(address(0)), 0);
    }

    function test_slotChanged(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint256 newMaxTotalAssetsInUnderlying = 10 ** 18 + 5 * 10 ** 17;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxTotalAssetsInUnderlyingChanged(
            ltv.maxTotalAssetsInUnderlying(), newMaxTotalAssetsInUnderlying
        );
        ltv.setMaxTotalAssetsInUnderlying(newMaxTotalAssetsInUnderlying);

        assertEq(ltv.maxTotalAssetsInUnderlying(), newMaxTotalAssetsInUnderlying);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint256 newMaxTotalAssetsInUnderlying = ltv.maxTotalAssetsInUnderlying();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxTotalAssetsInUnderlying(newMaxTotalAssetsInUnderlying);
    }
}
