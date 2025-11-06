// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "utils/BalancedTest.t.sol";
import {ILTV} from "../src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "../src/errors/IAdministrationErrors.sol";

contract GuardianTest is BalancedTest {
    function test_allowDisableFunctions(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLtv)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = dummyLtv.deposit.selector;

        dummyLtv.allowDisableFunctions(signatures, true);
        assertTrue(dummyLtv._isFunctionDisabled(signatures[0]));

        dummyLtv.allowDisableFunctions(signatures, false);
        assertFalse(dummyLtv._isFunctionDisabled(signatures[0]));

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLtv.allowDisableFunctions(signatures, true);
    }

    function test_setIsDepositDisabled(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLtv)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        dummyLtv.setIsDepositDisabled(true);
        assertTrue(dummyLtv.isDepositDisabled());

        dummyLtv.setIsDepositDisabled(false);
        assertFalse(dummyLtv.isDepositDisabled());

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLtv.setIsDepositDisabled(true);
    }

    function test_setIsWithdrawDisabled(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address guardian = ILTV(address(dummyLtv)).guardian();
        vm.assume(user != guardian);
        vm.startPrank(guardian);

        dummyLtv.setIsWithdrawDisabled(true);
        assertTrue(dummyLtv.isWithdrawDisabled());

        dummyLtv.setIsWithdrawDisabled(false);
        assertFalse(dummyLtv.isWithdrawDisabled());

        // Should revert if not guardian
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        dummyLtv.setIsWithdrawDisabled(true);
    }
}
