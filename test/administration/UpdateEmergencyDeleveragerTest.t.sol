// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import {IAdministrationEvents} from "../../src/events/IAdministrationEvents.sol";

contract UpdateEmergencyDeleveragerTest is BaseTest {
    function test_setAndCheckChangesApplied(DefaultTestData memory data, address newAddress)
        public
        testWithPredefinedDefaultValues(data)
    {
        address oldEmergencyDeleverager = ltv.emergencyDeleverager();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.EmergencyDeleveragerUpdated(oldEmergencyDeleverager, newAddress);
        ltv.updateEmergencyDeleverager(newAddress);
        vm.stopPrank();
        assertEq(ltv.emergencyDeleverager(), newAddress);
    }

    function test_checkCanSetZeroAddresses(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        address oldEmergencyDeleverager = ltv.emergencyDeleverager();
        vm.startPrank(data.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.EmergencyDeleveragerUpdated(oldEmergencyDeleverager, address(0));
        ltv.updateEmergencyDeleverager(address(0));
        vm.stopPrank();
        assertEq(ltv.emergencyDeleverager(), address(0));
    }

    function test_pickRandomRestrictedFunction(
        DefaultTestData memory data,
        address newAddress,
        address anotherNewAddress
    ) public testWithPredefinedDefaultValues(data) {
        vm.assume(newAddress != anotherNewAddress);
        vm.prank(data.owner);
        ltv.updateEmergencyDeleverager(newAddress);

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true, "");
        deal(address(borrowToken), newAddress, borrowAssets);
        vm.startPrank(newAddress);
        borrowToken.approve(address(ltv), borrowAssets);
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);
        vm.stopPrank();

        vm.prank(data.owner);
        ltv.updateEmergencyDeleverager(anotherNewAddress);

        vm.prank(newAddress);
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.OnlyEmergencyDeleveragerInvalidCaller.selector, newAddress)
        );
        ltv.deleverageAndWithdraw(0, 0, 1);

        vm.prank(anotherNewAddress);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.VaultAlreadyDeleveraged.selector));
        ltv.deleverageAndWithdraw(0, 0, 1);
    }
}
