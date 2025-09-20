// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";

contract SimpleMockOracleConnector is IOracleConnector {
    error MockOracleError();

    function getPriceCollateralOracle(bytes calldata) external pure override returns (uint256) {
        revert MockOracleError();
    }

    function getPriceBorrowOracle(bytes calldata) external pure override returns (uint256) {
        revert MockOracleError();
    }

    function initializeOracleConnectorData(bytes calldata) external {}
}

contract SetOracleConnectorTest is BaseTest {
    SimpleMockOracleConnector public mockOracleConnector;

    function test_setAndCheckAppliedChanges(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockOracleConnector = new SimpleMockOracleConnector();
        address oldOracleConnector = address(ltv.oracleConnector());

        vm.prank(defaultData.owner);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.OracleConnectorUpdated(oldOracleConnector, "", address(mockOracleConnector), "");
        ltv.setOracleConnector(address(mockOracleConnector), "");

        assertEq(address(ltv.oracleConnector()), address(mockOracleConnector));
    }

    function test_mockOracleConnectorWithDeposit(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockOracleConnector = new SimpleMockOracleConnector();

        vm.prank(defaultData.owner);
        ltv.setOracleConnector(address(mockOracleConnector), "");

        assertEq(address(ltv.oracleConnector()), address(mockOracleConnector));

        address user = address(this);
        uint256 amount = 100;

        deal(address(borrowToken), user, amount);
        vm.startPrank(user);
        borrowToken.approve(address(ltv), amount);

        vm.expectRevert(abi.encodeWithSelector(SimpleMockOracleConnector.MockOracleError.selector));
        ltv.deposit(amount, user);

        vm.stopPrank();
    }

    function test_onlyOwnerCanSetOracleConnector(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.owner);
        vm.assume(user != address(0));

        mockOracleConnector = new SimpleMockOracleConnector();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ltv.setOracleConnector(address(mockOracleConnector), "");
    }
}
