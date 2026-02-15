// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {LTV} from "src/elements/LTV.sol";

contract PostGovernor is Script, StdCheats, StdAssertions {
    function run() public view {
        LTV ltv = LTV(0xa260b049ddD6567E739139404C7554435c456d9E);
        assertEq(ltv.balanceOf(0xF06b3310486F872AB6808f6602aF65a0ef0F48f8), 0);
        assertEq(ltv.balanceOf(0x93547406B3219E954754613871104780c52ABb35), 234104196087869378);
    }
}
