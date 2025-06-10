// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import {IAdministrationEvents} from "../../src/events/IAdministrationEvents.sol";

contract UpdateGuardianTest is BaseTest {
    function test_setAndCheckChangesApplied(DefaultTestData memory data, address newAddress)
        public
        testWithPredefinedDefaultValues(data)
    {
        address oldGuardian = ltv.guardian();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GuardianUpdated(oldGuardian, newAddress);
        ltv.updateGuardian(newAddress);
        vm.stopPrank();
        assertEq(ltv.guardian(), newAddress);
    }

    function test_checkCanSetZeroAddresses(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        address oldGuardian = ltv.guardian();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GuardianUpdated(oldGuardian, address(0));
        ltv.updateGuardian(address(0));
        vm.stopPrank();
        assertEq(ltv.guardian(), address(0));
    }

    /// forge-config: default.fuzz.runs = 10
    function test_pickRandomRestrictedFunction(
        DefaultTestData memory data,
        address newAddress,
        address anotherNewAddress
    ) public testWithPredefinedDefaultValues(data) {
        vm.startPrank(data.owner);
        ltv.updateGuardian(newAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        ltv.setIsDepositDisabled(true);
        vm.stopPrank();

        vm.startPrank(data.owner);
        ltv.updateGuardian(anotherNewAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, newAddress));
        ltv.setIsDepositDisabled(false);
        vm.stopPrank();

        vm.startPrank(anotherNewAddress);
        ltv.setIsDepositDisabled(false);
        vm.stopPrank();
    }
}
