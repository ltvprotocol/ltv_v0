// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {LTV} from "src/elements/LTV.sol";
import {IERC20Errors} from "src/errors/IERC20Errors.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {UpgradeableBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";

// forge-lint: disable-start
contract TestSavingMission is Script, StdCheats, StdAssertions {
    function setUp() public {}

    function run() public {
        // current proxy address
        LTV ltv = LTV(0xa260b049ddD6567E739139404C7554435c456d9E);
        address owner = ltv.owner();
        address governor = ltv.governor();
        address guardian = ltv.guardian();
        // current beacon address
        UpgradeableBeacon beacon = UpgradeableBeacon(0x2a53522265dA2f3cC0bE3D824b2f3c47A8Fe1Fc9);

        // vm.prank(guardian);
        // ltv.setIsProtocolPaused(true);

        vm.prank(owner);
        // new implementation address
        beacon.upgradeTo(0x0cE0Bd78fB017E5d83b8cAeb659e3286AFD25847);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.executeLowLevelRebalanceShares(int256(0));

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.transfer(address(0), 1000000000000000000000000000000000000000);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.deposit(1000000000000000000000000000000000000000, address(0));

        vm.prank(guardian);
        ltv.setIsProtocolPaused(false);

        // balance of randUser1 is 1756271010760217887
        address randUser1 = 0x91A98Fd033434aDF63223F88064c95A89E08061C;
        // balance of randUser2 is 0
        address randUser2 = 0xe15CFa5Cce5487D323f48Aed5FcA0A08e47078d9;

        vm.prank(randUser1);
        ltv.transfer(randUser2, 10 ** 18);

        assertEq(ltv.balanceOf(randUser1), 1756271010760217887 - 10 ** 18);
        assertEq(ltv.balanceOf(randUser2), 10 ** 18);

        vm.prank(guardian);
        ltv.setIsProtocolPaused(true);

        address _temp = 0xF06b3310486F872AB6808f6602aF65a0ef0F48f8;
        address cleanAddress = address(uint160(uint256(keccak256("cleanAddress"))));

        uint256 balanceBefore = ltv.balanceOf(_temp);
        vm.startPrank(governor);
        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(_temp, cleanAddress, balanceBefore);
        ltv.executeSpecificTransfer(cleanAddress);

        assertEq(ltv.balanceOf(_temp), 0);
        assertEq(ltv.balanceOf(cleanAddress), balanceBefore);

        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        ltv.executeSpecificTransfer(cleanAddress);

        vm.stopPrank();

        vm.prank(owner);
        beacon.upgradeTo(0xd7AD059e339D12a1e8FEB116DA105d45B8cE2961);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.executeLowLevelRebalanceShares(int256(0));

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.transfer(address(0), 1000000000000000000000000000000000000000);

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.deposit(1000000000000000000000000000000000000000, address(0));

        vm.prank(guardian);
        ltv.setIsProtocolPaused(false);

        vm.prank(randUser2);
        ltv.transfer(randUser1, 10 ** 18);
        assertEq(ltv.balanceOf(randUser1), 1756271010760217887);
        assertEq(ltv.balanceOf(randUser2), 0);
    }
}
// forge-lint: disable-end
