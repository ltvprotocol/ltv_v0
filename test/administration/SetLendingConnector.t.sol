// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/interfaces/ILendingConnector.sol";

error UnexpectedMockSupply();
error UnexpectedMockWithdraw();
error UnexpectedMockBorrow();
error UnexpectedMockRepay();

contract MockLendingConnector is ILendingConnector {
    uint256 public constant collateralAssets = 2 * 10 ** 18;
    uint256 public constant borrowAssets = 3 * 10 ** 18;

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

    function getRealCollateralAssets(bool) external pure override returns (uint256) {
        return collateralAssets;
    }

    function getRealBorrowAssets(bool) external pure override returns (uint256) {
        return borrowAssets;
    }
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

        assertEq(address(ltv.getLendingConnector()), address(mockLendingConnector));

        address user = address(this);
        uint256 amount = 100;

        deal(address(borrowToken), user, amount);
        vm.startPrank(user);
        borrowToken.approve(address(ltv), amount);

        vm.expectRevert();
        ltv.deposit(amount, user);

        vm.stopPrank();
    }

    function test_failIfNotOwner(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.owner);
        vm.assume(user != defaultData.governor);
        vm.assume(user != address(0));

        mockLendingConnector = new MockLendingConnector();

        vm.prank(user);
        vm.expectRevert();
        ltv.setLendingConnector(address(mockLendingConnector));
    }
}
