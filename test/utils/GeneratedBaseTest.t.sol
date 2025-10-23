// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTestInit} from "test/utils/BaseTest.t.sol";
import {DummyModulesBaseTest} from "test/utils/DummyModulesBaseTest.t.sol";

contract GeneratedBaseTest is DummyModulesBaseTest {
    modifier initializeGeneratedTest(
        uint256 realBorrow,
        uint256 realCollateral,
        int256 futureBorrow,
        int256 futureCollateral,
        int256 auctionReward,
        uint16 auctionStep
    ) {
        BaseTestInit memory initData = BaseTestInit({
            owner: msg.sender,
            guardian: msg.sender,
            governor: msg.sender,
            emergencyDeleverager: msg.sender,
            feeCollector: address(1),
            futureBorrow: futureBorrow,
            futureCollateral: futureCollateral,
            auctionReward: auctionReward,
            startAuction: auctionStep,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: realCollateral,
            borrowAssets: realBorrow,
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            collateralPrice: 10 ** 20,
            borrowPrice: 10 ** 20,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            zeroAddressTokens: 0,
            softLiquidationFeeDividend: 1,
            softLiquidationFeeDivider: 100,
            softLiquidationLtvDividend: 1,
            softLiquidationLtvDivider: 1
        });
        initializeDummyTest(initData);
        ltv.mintFreeTokens(ltv.totalAssets(), address(this));

        vm.stopPrank();
        deal(address(borrowToken), address(this), type(uint112).max);
        deal(address(collateralToken), address(this), type(uint112).max);
        borrowToken.approve(address(ltv), type(uint112).max);
        collateralToken.approve(address(ltv), type(uint112).max);
        _;
    }
}
