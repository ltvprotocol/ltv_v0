// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILTV} from "../../../src/interfaces/ILTV.sol";
import {AllFunctionsInvariantWrapper} from "./AllFunctionsInvariantWrapper.t.sol";
import {BaseInvariantTest} from "./BaseInvariantTest.t.sol";

contract BaseAllFunctionsInvariantTest is BaseInvariantTest {
    AllFunctionsInvariantWrapper internal _wrapper;

    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    function createWrapper() internal override {
        _wrapper = new AllFunctionsInvariantWrapper(ILTV(address(ltv)), actors());

        _wrapper.fuzzMint(1, 0, 100);

        // Set less maximum total assets to avoid overflows
        vm.startPrank(ltv.governor());
        ltv.setMaxTotalAssetsInUnderlying(type(uint112).max);
        vm.stopPrank();
    }

    function afterInvariant() public view virtual override {
        // Call parent to check max growth fee
        super.afterInvariant();

        // Verify that auction rewards were received during testing
        // This ensures the auction mechanism is functioning properly
        assertTrue(_wrapper.auctionRewardsReceived());
    }
}
