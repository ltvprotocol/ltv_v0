// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";

error UnexpectedMockSupply();
error UnexpectedMockWithdraw();
error UnexpectedMockBorrow();
error UnexpectedMockRepay();
error UnexpectedMockGetRealCollateralAssets();
error UnexpectedMockGetRealBorrowAssets();

contract MockLendingConnector is ILendingConnector {
    function supply(uint256) external pure override {
        revert UnexpectedMockSupply();
    }

    function withdraw(uint256) external pure override {
        revert UnexpectedMockWithdraw();
    }

    function borrow(uint256) external pure override {
        revert UnexpectedMockBorrow();
    }

    function repay(uint256) external pure override {
        revert UnexpectedMockRepay();
    }

    function getRealCollateralAssets(bool, bytes calldata) external pure override returns (uint256) {
        revert UnexpectedMockGetRealCollateralAssets();
    }

    function getRealBorrowAssets(bool, bytes calldata) external pure override returns (uint256) {
        revert UnexpectedMockGetRealBorrowAssets();
    }

    function initializeProtocol(bytes memory) external pure {}
}

contract SetLendingConnectorTest is BaseTest {
    MockLendingConnector public mockLendingConnector;

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockLendingConnector = new MockLendingConnector();
        address oldLendingConnector = address(ltv.getLendingConnector());

        vm.prank(defaultData.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.LendingConnectorUpdated(oldLendingConnector, address(mockLendingConnector));
        ltv.setLendingConnector(address(mockLendingConnector));

        assertEq(address(ltv.getLendingConnector()), address(mockLendingConnector));
    }

    function test_mockExecution(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockLendingConnector = new MockLendingConnector();

        vm.prank(defaultData.owner);
        ltv.setLendingConnector(address(mockLendingConnector));

        vm.expectRevert(UnexpectedMockGetRealCollateralAssets.selector);
        ltv.deposit(0, address(this));

        vm.stopPrank();
    }

    function test_failIfNotOwner(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.owner);

        mockLendingConnector = new MockLendingConnector();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ltv.setLendingConnector(address(mockLendingConnector));
    }
}
