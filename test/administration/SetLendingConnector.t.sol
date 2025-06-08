// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/interfaces/ILendingConnector.sol";

contract MockLendingConnector is ILendingConnector {
    bool public supplyCalled;
    bool public withdrawCalled;
    bool public borrowCalled;
    bool public repayCalled;
    uint256 public lastSupplyAmount;
    uint256 public lastWithdrawAmount;

    function supply(uint256 assets) external override {
        supplyCalled = true;
        lastSupplyAmount = assets;
    }

    function withdraw(uint256 assets) external override {
        withdrawCalled = true;
        lastWithdrawAmount = assets;
    }

    function borrow(uint256 /* assets */ ) external override {
        borrowCalled = true;
    }

    function repay(uint256 /* assets */ ) external override {
        repayCalled = true;
    }

    function getRealCollateralAssets(bool) external pure override returns (uint256) {
        return 0;
    }

    function getRealBorrowAssets(bool) external pure override returns (uint256) {
        return 0;
    }

    function reset() external {
        supplyCalled = false;
        withdrawCalled = false;
        borrowCalled = false;
        repayCalled = false;
        lastSupplyAmount = 0;
        lastWithdrawAmount = 0;
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

        mockLendingConnector.reset();
        assertEq(mockLendingConnector.supplyCalled(), false);

        vm.startPrank(address(ltv));

        uint256 testAmount = 100;
        mockLendingConnector.supply(testAmount);

        vm.stopPrank();

        assertEq(mockLendingConnector.supplyCalled(), true);
        assertEq(mockLendingConnector.lastSupplyAmount(), testAmount);
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
