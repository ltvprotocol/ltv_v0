// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BalancedTest.t.sol";

contract OwnerTest is BalancedTest {
    function test_setLendingConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address mockConnector = address(0x9876);

        dummyLTV.setLendingConnector(mockConnector, "");
        assertEq(address(ILTV(address(dummyLTV)).lendingConnector()), mockConnector);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLTV.setLendingConnector(address(0), "");
    }

    function test_setOracleConnector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address mockConnector = address(0x9876);

        dummyLTV.setOracleConnector(mockConnector, "");
        assertEq(address(dummyLTV.oracleConnector()), mockConnector);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLTV.setOracleConnector(address(0), "");
    }

    function test_updateEmergencyDeleverager(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newDeleverager = address(0x5678);

        dummyLTV.updateEmergencyDeleverager(newDeleverager);
        assertEq(dummyLTV.emergencyDeleverager(), newDeleverager);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLTV.updateEmergencyDeleverager(address(0));
    }

    function test_transferOwnership(address owner, address user, address newOwner)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.assume(newOwner != user);
        vm.assume(newOwner != address(0));
        vm.startPrank(owner);

        ILTV(address(dummyLTV)).transferOwnership(newOwner);
        assertEq(ILTV(address(dummyLTV)).owner(), newOwner);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLTV)).transferOwnership(address(0));
    }

    function test_updateGuardian(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newGuardian = address(0x5678);

        ILTV(address(dummyLTV)).updateGuardian(newGuardian);
        assertEq(ILTV(address(dummyLTV)).guardian(), newGuardian);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLTV)).updateGuardian(address(0));
    }

    function test_updateGovernor(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.startPrank(owner);
        address newGovernor = address(0x5678);

        ILTV(address(dummyLTV)).updateGovernor(newGovernor);
        assertEq(ILTV(address(dummyLTV)).governor(), newGovernor);

        // Should revert if not owner
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        ILTV(address(dummyLTV)).updateGovernor(address(0));
    }

    function test_renounceOwnership(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        dummyLTV.renounceOwnership();

        vm.startPrank(owner);
        dummyLTV.renounceOwnership();
        assertEq(ILTV(address(dummyLTV)).owner(), address(0));

        vm.startPrank(owner);
    }
}
