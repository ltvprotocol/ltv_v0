// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/AllFunctionsInvariantWrapper.t.sol";
import "./utils/BaseInvariantTest.t.sol";

contract AllFunctionsInvariantTest is BaseInvariantTest {
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

    function invariant_allFunctions() public {}

    function afterInvariant() public view override {
        // // Call parent to check max growth fee
        // super.afterInvariant();

        // // Verify that auction rewards were received during testing
        // // This ensures the auction mechanism is functioning properly
        // assertTrue(_wrapper.auctionRewardsReceived());
    }
}
