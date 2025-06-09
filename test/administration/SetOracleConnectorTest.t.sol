// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/interfaces/IOracleConnector.sol";

contract MockOracleConnector is IOracleConnector {
    function getPriceCollateralOracle() external pure override returns (uint256) {
        revert();
    }

    function getPriceBorrowOracle() external pure override returns (uint256) {
        revert();
    }
}

contract SetOracleConnectorTest is BaseTest {
    MockOracleConnector public mockOracleConnector;

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockOracleConnector = new MockOracleConnector();
        address oldOracleConnector = address(ltv.oracleConnector());

        vm.prank(defaultData.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.OracleConnectorUpdated(oldOracleConnector, address(mockOracleConnector));
        ltv.setOracleConnector(address(mockOracleConnector));

        assertEq(address(ltv.oracleConnector()), address(mockOracleConnector));
    }

    function test_mockExecution(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockOracleConnector = new MockOracleConnector();

        vm.prank(defaultData.owner);
        ltv.setOracleConnector(address(mockOracleConnector));

        assertEq(address(ltv.oracleConnector()), address(mockOracleConnector));

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

        mockOracleConnector = new MockOracleConnector();

        vm.prank(user);
        vm.expectRevert();
        ltv.setOracleConnector(address(mockOracleConnector));
    }
}