// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";

contract SetWhitelistRegistryTest is BaseTest {
    function test_failIfZeroDuringActivatedWhitelist(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.startPrank(defaultData.governor);
        ltv.setWhitelistRegistry(address(new WhitelistRegistry(defaultData.owner, address(0))));
        ltv.setIsWhitelistActivated(true);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.WhitelistIsActivated.selector));
        ltv.setWhitelistRegistry(address(0));
    }

    function test_whitelistedUserChanges(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.feeCollector);
        vm.assume(user != address(0));
        deal(address(borrowToken), user, type(uint112).max);
        vm.prank(user);
        borrowToken.approve(address(ltv), type(uint112).max);

        vm.startPrank(defaultData.governor);
        WhitelistRegistry registry = new WhitelistRegistry(defaultData.owner, address(0));
        ltv.setWhitelistRegistry(address(registry));
        ltv.setIsWhitelistActivated(true);

        vm.startPrank(defaultData.owner);
        registry.addAddressToWhitelist(user);
        vm.stopPrank();

        // check user is whitelisted
        assertEq(IWhitelistRegistry(ltv.whitelistRegistry()).isAddressWhitelisted(user), true);
        vm.prank(user);
        ltv.deposit(10 ** 10, user);

        vm.startPrank(defaultData.governor);
        ltv.setWhitelistRegistry(address(new WhitelistRegistry(defaultData.owner, address(0))));
        vm.stopPrank();

        // check user is not whitelisted
        assertEq(IWhitelistRegistry(ltv.whitelistRegistry()).isAddressWhitelisted(user), false);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user));
        ltv.deposit(10 ** 10, user);
    }

    function test_checkSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        WhitelistRegistry registry = new WhitelistRegistry(defaultData.owner, address(0));
        ltv.setWhitelistRegistry(address(registry));
        vm.stopPrank();

        assertEq(address(ltv.whitelistRegistry()), address(registry));
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setWhitelistRegistry(address(0));
    }
}
