// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import {IAdministrationEvents} from "../../src/events/IAdministrationEvents.sol";

contract UpdateGovernorTest is BaseTest {
    function test_setAndCheckChangesApplied(DefaultTestData memory data, address newAddress)
        public
        testWithPredefinedDefaultValues(data)
    {
        address oldGovernor = ltv.governor();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GovernorUpdated(oldGovernor, newAddress);
        ltv.updateGovernor(newAddress);
        vm.stopPrank();
        assertEq(ltv.governor(), newAddress);
    }

    function test_checkCanSetZeroAddresses(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        address oldGovernor = ltv.governor();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GovernorUpdated(oldGovernor, address(0));
        ltv.updateGovernor(address(0));
        vm.stopPrank();
        assertEq(ltv.governor(), address(0));
    }

    function test_pickRandomRestrictedFunction(
        DefaultTestData memory data,
        address newAddress,
        address anotherNewAddress
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(newAddress != anotherNewAddress);
        vm.startPrank(data.owner);
        ltv.updateGovernor(newAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        ltv.setTargetLTV(74, 100);
        vm.stopPrank();

        vm.startPrank(data.owner);
        ltv.updateGovernor(anotherNewAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, newAddress));
        ltv.setTargetLTV(75, 100);
        vm.stopPrank();

        vm.startPrank(anotherNewAddress);
        ltv.setTargetLTV(75, 100);
        vm.stopPrank();
    }
}
