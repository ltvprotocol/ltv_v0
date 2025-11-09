// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "./utils/BaseTest.t.sol";
import {IAdministrationErrors} from "../src/errors/IAdministrationErrors.sol";

contract SoftLiquidationTest is BaseTest {
    BaseTestInit private defaultData = BaseTestInit({
        owner: address(42),
        guardian: address(43),
        governor: address(44),
        emergencyDeleverager: address(45),
        feeCollector: address(46),
        futureBorrow: 0,
        futureCollateral: 0,
        auctionReward: 0,
        startAuction: 0,
        collateralSlippage: 10 ** 16,
        borrowSlippage: 10 ** 16,
        maxTotalAssetsInUnderlying: type(uint128).max,
        collateralAssets: 100 * 10 ** 18,
        borrowAssets: 98 * 10 ** 18,
        maxSafeLtvDividend: 9,
        maxSafeLtvDivider: 10,
        minProfitLtvDividend: 5,
        minProfitLtvDivider: 10,
        targetLtvDividend: 75,
        targetLtvDivider: 100,
        maxGrowthFeeDividend: 1,
        maxGrowthFeeDivider: 5,
        collateralPrice: 10 ** 18,
        borrowPrice: 10 ** 18,
        maxDeleverageFeeDividend: 1,
        maxDeleverageFeeDivider: 50,
        zeroAddressTokens: 25 * 10 ** 18,
        softLiquidationFeeDividend: 1,
        softLiquidationFeeDivider: 100,
        softLiquidationLtvDividend: 97,
        softLiquidationLtvDivider: 100
    });

    function test_softLiquidation() public {
        initializeTest(defaultData);

        address emergencyDeleverager = defaultData.emergencyDeleverager;
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), emergencyDeleverager, 10 ** 18);
        borrowToken.approve(address(ltv), 10 ** 18);

        assertEq(ltv.totalAssets(), 2 * 10 ** 18 + 10000);
        ltv.softLiquidation(10 ** 18);
        assertEq(ltv.totalAssets(), 2 * 10 ** 18 + 10000 - 10 ** 16);
        assertEq(ltv.getRealBorrowAssets(true), 97 * 10 ** 18);
        assertEq(ltv.getRealCollateralAssets(true), 99 * 10 ** 18 - 10 ** 16);
    }

    function test_softLiquidationExceedsLtv() public {
        initializeTest(defaultData);

        address emergencyDeleverager = defaultData.emergencyDeleverager;
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), emergencyDeleverager, 50 * 10 ** 18);
        borrowToken.approve(address(ltv), 50 * 10 ** 18);

        assertEq(ltv.totalAssets(), 2 * 10 ** 18 + 10000);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.SoftLiquidationResultBelowSoftLiquidationLtv.selector,
                48 * 10 ** 18,
                495 * 10 ** 17,
                97,
                100
            )
        );
        ltv.softLiquidation(50 * 10 ** 18);
    }

    function test_softLiquidationFeeTooHigh() public {
        initializeTest(defaultData);

        vm.prank(defaultData.governor);
        ltv.setSoftLiquidationFee(1, 10);

        address emergencyDeleverager = defaultData.emergencyDeleverager;
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), emergencyDeleverager, 10 ** 18);
        borrowToken.approve(address(ltv), 10 ** 18);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.SoftLiquidationFeeTooHigh.selector));
        ltv.softLiquidation(10 ** 18);
    }
}
