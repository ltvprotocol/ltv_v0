// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./DummyModulesBaseTest.t.sol";

contract BalancedTest is DummyModulesBaseTest {
    modifier initializeBalancedTest(
        address owner,
        address user,
        uint256 borrowAmount,
        int256 futureBorrow,
        int256 futureCollateral,
        int256 auctionReward
    ) {
        vm.assume(owner != address(0));
        vm.assume(user != address(0));
        vm.assume(user != owner);
        vm.assume(int256(borrowAmount) >= futureBorrow);
        {
            uint256 supplyBalance;
            uint256 borrowBalance;

            if (futureBorrow < 0) {
                supplyBalance = uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2);
                borrowBalance = uint256(int256(borrowAmount) * 10 * 3 - futureBorrow - auctionReward);
            } else {
                supplyBalance = uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2 - auctionReward / 2);
                borrowBalance = uint256(int256(borrowAmount) * 10 * 3 - futureBorrow);
                auctionReward = auctionReward / 2;
            }

            BaseTestInit memory initData = BaseTestInit({
                owner: owner,
                guardian: address(123),
                governor: address(132),
                emergencyDeleverager: address(213),
                feeCollector: address(231),
                futureBorrow: futureBorrow,
                futureCollateral: futureCollateral / 2,
                auctionReward: auctionReward,
                startAuction: uint56(1000 / 2),
                collateralSlippage: 0,
                borrowSlippage: 0,
                maxTotalAssetsInUnderlying: type(uint128).max,
                collateralAssets: supplyBalance,
                borrowAssets: borrowBalance,
                maxSafeLTVDividend: 9,
                maxSafeLTVDivider: 10,
                minProfitLTVDividend: 5,
                minProfitLTVDivider: 10,
                targetLTVDividend: 75,
                targetLTVDivider: 100,
                maxGrowthFeeDividend: 1,
                maxGrowthFeeDivider: 5,
                collateralPrice: 2 * 10 ** 20,
                borrowPrice: 10 ** 20,
                maxDeleverageFeeDividend: 1,
                maxDeleverageFeeDivider: 50,
                zeroAddressTokens: borrowAmount * 10
            });

            initializeDummyTest(initData);

            // transfer preminted tokens to owner
            vm.startPrank(address(0));
            ltv.transfer(address(owner), ltv.balanceOf(address(0)));
            vm.stopPrank();
        }

        deal(address(borrowToken), user, type(uint112).max);
        deal(address(collateralToken), user, type(uint112).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint112).max);
        borrowToken.approve(address(ltv), type(uint112).max);
        _;
    }
}
