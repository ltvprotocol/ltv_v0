// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract UpdateRolesTest is BaseTest {
    function updateRoleCalls(address newAddress) public pure returns (bytes[] memory) {
        bytes[] memory selectors = new bytes[](3);
        selectors[0] = abi.encodeCall(ILTV.updateEmergencyDeleverager, (newAddress));
        selectors[1] = abi.encodeCall(ILTV.updateGovernor, (newAddress));
        selectors[2] = abi.encodeCall(ILTV.updateGuardian, (newAddress));
        return selectors;
    }

    function test_setAndCheckChangesApplied(DefaultTestData memory data, address newAddress)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(newAddress != address(0));
        vm.assume(newAddress != data.owner);
        vm.assume(newAddress != data.guardian);
        vm.assume(newAddress != data.governor);
        vm.assume(newAddress != data.emergencyDeleverager);
        vm.assume(newAddress != data.feeCollector);

        address oldEmergencyDeleverager = ltv.emergencyDeleverager();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.EmergencyDeleveragerUpdated(oldEmergencyDeleverager, newAddress);
        ltv.updateEmergencyDeleverager(newAddress);
        vm.stopPrank();
        assertEq(ltv.emergencyDeleverager(), newAddress);

        address oldGovernor = ltv.governor();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GovernorUpdated(oldGovernor, newAddress);
        ltv.updateGovernor(newAddress);
        vm.stopPrank();
        assertEq(ltv.governor(), newAddress);

        address oldGuardian = ltv.guardian();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GuardianUpdated(oldGuardian, newAddress);
        ltv.updateGuardian(newAddress);
        vm.stopPrank();
        assertEq(ltv.guardian(), newAddress);
    }

    function test_checkCanSetZeroAddresses(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        address oldEmergencyDeleverager = ltv.emergencyDeleverager();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.EmergencyDeleveragerUpdated(oldEmergencyDeleverager, address(0));
        ltv.updateEmergencyDeleverager(address(0));
        vm.stopPrank();
        assertEq(ltv.emergencyDeleverager(), address(0));

        address oldGovernor = ltv.governor();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GovernorUpdated(oldGovernor, address(0));
        ltv.updateGovernor(address(0));
        vm.stopPrank();
        assertEq(ltv.governor(), address(0));

        address oldGuardian = ltv.guardian();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.GuardianUpdated(oldGuardian, address(0));
        ltv.updateGuardian(address(0));
        vm.stopPrank();
        assertEq(ltv.guardian(), address(0));
    }

    function test_pickRandomRestrictedFunction(DefaultTestData memory data, address newAddress)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(newAddress != address(0));
        vm.assume(newAddress != data.owner);
        vm.assume(newAddress != data.guardian);
        vm.assume(newAddress != data.governor);
        vm.assume(newAddress != data.emergencyDeleverager);
        vm.assume(newAddress != data.feeCollector);

        vm.startPrank(data.owner);
        ltv.updateGovernor(newAddress);
        ltv.updateGuardian(newAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        ltv.setTargetLTV(74 * 10 ** 16);
        ltv.setIsDepositDisabled(true);
        vm.stopPrank();

        address anotherNewAddress = makeAddr("anotherNew");
        vm.startPrank(data.owner);
        ltv.updateGovernor(anotherNewAddress);
        ltv.updateGuardian(anotherNewAddress);
        vm.stopPrank();

        vm.startPrank(newAddress);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, newAddress));
        ltv.setTargetLTV(75 * 10 ** 16);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, newAddress));
        ltv.setIsDepositDisabled(false);
        vm.stopPrank();

        vm.startPrank(anotherNewAddress);
        ltv.setTargetLTV(75 * 10 ** 16);
        ltv.setIsDepositDisabled(false);
        vm.stopPrank();
    }
}
