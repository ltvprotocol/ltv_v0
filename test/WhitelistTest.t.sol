// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";

contract WhitelistTest is BalancedTest {
    function test_whitelist(address owner, address user, address randUser)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.assume(user != randUser);
        vm.assume(user != ltv.feeCollector());
        vm.stopPrank();
        address governor = ILTV(address(dummyLtv)).governor();
        vm.startPrank(governor);
        deal(address(borrowToken), randUser, type(uint112).max);

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(governor);
        dummyLtv.setWhitelistRegistry(address(whitelistRegistry));

        dummyLtv.setIsWhitelistActivated(true);
        whitelistRegistry.addAddressToWhitelist(randUser);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user));
        dummyLtv.deposit(10 ** 17, user);

        vm.startPrank(randUser);
        borrowToken.approve(address(dummyLtv), 10 ** 17);
        dummyLtv.deposit(10 ** 17, randUser);
    }
}
