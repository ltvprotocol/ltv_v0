// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./VaultInvariantTest.t.sol";

contract InvariantSetupTest is BasicInvariantTest {
    
    LTVVaultWrapper internal _wrapper;

    function wrapper() internal view override returns (address) {
        return address(_wrapper);
    }

    function createWrapper() internal override {
        _wrapper = new LTVVaultWrapper(ILTV(address(ltv)), actors());
    }

    function test_maxGrowthFeeCheckWorks() public {
        vm.roll(7100);
        _wrapper.mint(1, 0, 500);
        _wrapper.checkAndResetInvariants();
        assertTrue(_wrapper.maxGrowthFeeReceived());
    }

    function test_auctionRewardCheckWorks() public {
        _wrapper.deposit(10**20, 0, 1000);
        _wrapper.checkAndResetInvariants();
        _wrapper.redeem(10**16, 0, 100);
        _wrapper.checkAndResetInvariants();
        assertTrue(_wrapper.auctionRewardsReceived());
    }

    function test_dynamicOracleWorks() public {
        uint256 collateralPriceBefore = oracleConnector.getPriceCollateralOracle();
        vm.roll(100000);
        assertGt(oracleConnector.getPriceCollateralOracle(), collateralPriceBefore);
    }

    function test_dynamicLendingWorks() public {
        uint256 borrowBalanceBefore = ltv.getRealBorrowAssets(false);
        vm.roll(100000);
        assertGt(ltv.getRealBorrowAssets(false), borrowBalanceBefore);
    }

    function test_collateralGrowthFaster() public {
        uint256 totalAssetsBefore = ltv.totalAssets();
        vm.roll(100000);
        assertGt(ltv.totalAssets(), totalAssetsBefore);
    }
}
