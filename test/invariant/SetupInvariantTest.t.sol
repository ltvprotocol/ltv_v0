// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILTV} from "src/interfaces/ILTV.sol";
import {BaseInvariantTest} from "test/invariant/utils/BaseInvariantTest.t.sol";
import {VaultInvariantWrapper} from "test/invariant/VaultInvariantTest.t.sol";

contract SetupInvariantTest is BaseInvariantTest {
    VaultInvariantWrapper internal _wrapper;

    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    function createWrapper() internal override {
        _wrapper = new VaultInvariantWrapper(ILTV(address(ltv)), actors());
    }

    function test_maxGrowthFeeCheck() public {
        vm.roll(7100);
        _wrapper.fuzzMint(1, 0, 500);
        _wrapper.verifyAndResetInvariants();
        assertTrue(_wrapper.maxGrowthFeeReceived());
    }

    function test_auctionRewardCheck() public {
        _wrapper.fuzzDeposit(10 ** 20, 0, 1000);
        _wrapper.verifyAndResetInvariants();
        _wrapper.fuzzRedeem(10 ** 16, 0, 100);
        _wrapper.verifyAndResetInvariants();
        assertTrue(_wrapper.auctionRewardsReceived());
    }

    function test_dynamicOracle() public {
        uint256 initialCollateralPrice = oracleConnector.getPriceCollateralOracle();
        vm.roll(100000);
        assertGt(oracleConnector.getPriceCollateralOracle(), initialCollateralPrice);
    }

    function test_dynamicLending() public {
        uint256 initialBorrowBalance = ltv.getRealBorrowAssets(false);
        vm.roll(100000);
        assertGt(ltv.getRealBorrowAssets(false), initialBorrowBalance);
    }

    function test_collateralGrowthFasterThanBorrow() public {
        uint256 initialTotalAssets = ltv.totalAssets();
        vm.roll(100000);
        assertGt(ltv.totalAssets(), initialTotalAssets);
    }
}
