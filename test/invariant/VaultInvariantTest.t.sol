// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BasicInvariantTest} from "./utils/BasicInvariantTest.t.sol";
import {LTVVaultWrapper, ILTV} from "./utils/LTVVaultWrapper.sol";

contract VaultInvariantTest is BasicInvariantTest {
    LTVVaultWrapper internal _wrapper;

    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    function createWrapper() internal override {
        _wrapper = new LTVVaultWrapper(ILTV(address(ltv)), actors());
    }

    function setUp() public virtual override {
        super.setUp();

        _wrapper.mint(1, 0, 100);
    }

    function afterInvariant() public view override {
        super.afterInvariant();
        _wrapper.auctionRewardsReceived();
    }

    function invariant_vault() public pure {}
}
