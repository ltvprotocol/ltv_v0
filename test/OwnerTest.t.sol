// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {MockLendingConnector, MockOracleConnector} from "./utils/MockConnectors.t.sol";
import {DummySlippageConnector} from "src/dummy/DummySlippageConnector.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";

contract OwnerTest is BalancedTest {
    function test_setLendingConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        MockLendingConnector mockLendingConnector = new MockLendingConnector();
        vm.startPrank(owner);

        dummyLtv.setLendingConnector(address(mockLendingConnector), "");
        assertEq(address(ILTV(address(dummyLtv)).lendingConnector()), address(mockLendingConnector));

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLtv.setLendingConnector(address(0), "");
    }

    function test_setOracleConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        MockOracleConnector mockOracleConnector = new MockOracleConnector();

        dummyLtv.setOracleConnector(address(mockOracleConnector), "");
        assertEq(address(dummyLtv.oracleConnector()), address(mockOracleConnector));

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLtv.setOracleConnector(address(0), "");
    }

    function test_updateEmergencyDeleverager(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newDeleverager = address(0x5678);

        dummyLtv.updateEmergencyDeleverager(newDeleverager);
        assertEq(dummyLtv.emergencyDeleverager(), newDeleverager);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLtv.updateEmergencyDeleverager(address(0));
    }

    function test_transferOwnership(address owner, address user, address newOwner)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.assume(newOwner != user);
        vm.assume(newOwner != address(0));
        vm.startPrank(owner);

        ILTV(address(dummyLtv)).transferOwnership(newOwner);
        assertEq(ILTV(address(dummyLtv)).owner(), newOwner);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLtv)).transferOwnership(address(0));
    }

    function test_updateGuardian(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newGuardian = address(0x5678);

        ILTV(address(dummyLtv)).updateGuardian(newGuardian);
        assertEq(ILTV(address(dummyLtv)).guardian(), newGuardian);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLtv)).updateGuardian(address(0));
    }

    function test_updateGovernor(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newGovernor = address(0x5678);

        ILTV(address(dummyLtv)).updateGovernor(newGovernor);
        assertEq(ILTV(address(dummyLtv)).governor(), newGovernor);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLtv)).updateGovernor(address(0));
    }

    function test_renounceOwnership(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLtv.renounceOwnership();

        vm.startPrank(owner);
        dummyLtv.renounceOwnership();
        assertEq(ILTV(address(dummyLtv)).owner(), address(0));

        vm.startPrank(owner);
    }

    function test_setSlippageConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.assume(user != owner);
        vm.startPrank(owner);

        DummySlippageConnector provider = new DummySlippageConnector();
        bytes memory slippageConnectorData = abi.encode(10 ** 16, 10 ** 16);
        dummyLtv.setSlippageConnector(address(provider), slippageConnectorData);
        assertEq(address(dummyLtv.slippageConnector()), address(provider));
        assertEq(keccak256(dummyLtv.slippageConnectorGetterData()), keccak256(slippageConnectorData));

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLtv.setSlippageConnector(address(0), slippageConnectorData);
    }
}
