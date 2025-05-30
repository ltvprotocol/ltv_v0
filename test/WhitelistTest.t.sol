// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './utils/BalancedTest.t.sol';
import '../src/elements/WhitelistRegistry.sol';

contract WhitelistTest is BalancedTest {
    function test_whitelist(address owner, address user, address randUser) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.assume(user != randUser);
        vm.stopPrank();
        address governor = ILTV(address(dummyLTV)).governor();
        vm.startPrank(governor);
        deal(address(borrowToken), randUser, type(uint112).max);

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(governor);
        dummyLTV.setWhitelistRegistry(address(whitelistRegistry));

        dummyLTV.setIsWhitelistActivated(true);
        whitelistRegistry.addAddressToWhitelist(randUser);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user));
        dummyLTV.deposit(10 ** 17, user);

        vm.startPrank(randUser);
        borrowToken.approve(address(dummyLTV), 10 ** 17);
        dummyLTV.deposit(10 ** 17, randUser);
    }
}
