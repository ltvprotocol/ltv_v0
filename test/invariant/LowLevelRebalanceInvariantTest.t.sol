// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BasicInvariantTest} from "./utils/BasicInvariantTest.t.sol";
import {LTVLowLevelWrapper, ILTV} from "./utils/LTVLowLevelWrapper.sol";

contract LowLevelRebalanceInvariantTest is BasicInvariantTest {
    LTVLowLevelWrapper internal _wrapper;

    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    function createWrapper() internal override {
        _wrapper = new LTVLowLevelWrapper(ILTV(address(ltv)), actors());
    }

    function setUp() public override {
        super.setUp();
        vm.startPrank(ltv.governor());
        ltv.setMaxTotalAssetsInUnderlying(type(uint112).max);
        vm.stopPrank();
        _wrapper.executeLowLevelRebalanceShares(0, 0, 100);
    }

    function invariant_lowLevelRebalance() public {
        _wrapper.checkAndResetInvariants();
    }
}