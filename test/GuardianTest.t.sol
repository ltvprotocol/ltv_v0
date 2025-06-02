// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BalancedTest.t.sol";

contract GuardianTest is BalancedTest {
    function test_allowDisableFunctions(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = dummyLTV.deposit.selector;

        dummyLTV.allowDisableFunctions(signatures, true);
        assertTrue(dummyLTV._isFunctionDisabled(signatures[0]));

        dummyLTV.allowDisableFunctions(signatures, false);
        assertFalse(dummyLTV._isFunctionDisabled(signatures[0]));

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLTV.allowDisableFunctions(signatures, true);
    }

    function test_setIsDepositDisabled(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        dummyLTV.setIsDepositDisabled(true);
        assertTrue(dummyLTV.isDepositDisabled());

        dummyLTV.setIsDepositDisabled(false);
        assertFalse(dummyLTV.isDepositDisabled());

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLTV.setIsDepositDisabled(true);
    }

    function test_setIsWithdrawDisabled(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLTV)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        dummyLTV.setIsWithdrawDisabled(true);
        assertTrue(dummyLTV.isWithdrawDisabled());

        dummyLTV.setIsWithdrawDisabled(false);
        assertFalse(dummyLTV.isWithdrawDisabled());

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLTV.setIsWithdrawDisabled(true);
    }
}
