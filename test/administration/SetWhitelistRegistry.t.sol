// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../utils/BaseTest.t.sol';

contract SetWhitelistRegistryTest is BaseTest {
    function test_failIfZero(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        address newWhitelistRegistry = address(0);
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroWhitelistRegistry.selector));
        ltv.setWhitelistRegistry(newWhitelistRegistry);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != defaultData.governor);
    }
}