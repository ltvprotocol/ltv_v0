// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {LTV} from "src/elements/LTV.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";

// forge-lint: disable-start
contract BeforeAnything is Script, StdCheats, StdAssertions {
    function run() public {
        LTV ltv = LTV(0xa260b049ddD6567E739139404C7554435c456d9E);

        // balance of randUser1 is 1756271010760217887
        address randUser1 = 0x91A98Fd033434aDF63223F88064c95A89E08061C;
        // balance of randUser2 is 0
        address randUser2 = 0xe15CFa5Cce5487D323f48Aed5FcA0A08e47078d9;

        vm.prank(randUser1);
        ltv.transfer(randUser2, 10 ** 18);

        assertEq(ltv.balanceOf(randUser1), 1756271010760217887 - 10 ** 18);
        assertEq(ltv.balanceOf(randUser2), 10 ** 18);

        address guardian = ltv.guardian();

        vm.prank(guardian);
        ltv.setIsProtocolPaused(true);

        assertEq(ltv.isProtocolPaused(), true);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.executeLowLevelRebalanceShares(int256(0));

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.transfer(address(0), 1000000000000000000000000000000000000000);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.deposit(1000000000000000000000000000000000000000, address(0));

        vm.prank(guardian);
        ltv.setIsProtocolPaused(false);

        assertEq(ltv.isProtocolPaused(), false);

        vm.prank(randUser2);
        ltv.transfer(randUser1, 10 ** 18);

        assertEq(ltv.balanceOf(randUser1), 1756271010760217887);
        assertEq(ltv.balanceOf(randUser2), 0);
    }
}
// forge-lint: disable-end
