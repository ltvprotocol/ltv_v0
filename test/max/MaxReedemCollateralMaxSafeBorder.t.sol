// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "../utils/BaseTest.t.sol";
import {Constants} from "../../src/Constants.sol";

contract MaxReedemCollateralMaxSafeBorderTest is BaseTest {
    address internal user;

    function test_maxRedeemCollateralAtMaxSafeLTVBorder(uint256 collateralAssets) public {
        uint256 min = uint256((100 * (10 ** 19)) / uint256(42));

        uint256 checkCollateralAssets = bound(collateralAssets, min, 64 * min);

        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 0,
            futureCollateral: 0,
            auctionReward: 0,
            startAuction: 1000,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: checkCollateralAssets,
            borrowAssets: 90 * 10 ** 18,
            maxSafeLTVDividend: 9, // 90%
            maxSafeLTVDivider: 10,
            minProfitLTVDividend: 5,
            minProfitLTVDivider: 10,
            targetLTVDividend: 75,
            targetLTVDivider: 100,
            maxGrowthFeeDividend: 0,
            maxGrowthFeeDivider: 1,
            collateralPrice: 42 * 10 ** 17,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 0,
            maxDeleverageFeeDivider: 1,
            zeroAddressTokens: 25 * 10 ** 18
        });

        initializeTest(init);

        user = address(6);
        vm.prank(address(0));
        ltv.transfer(user, 25 * 10 ** 18);

        user = address(6);
        vm.startPrank(user);
        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);

        vm.startPrank(user);
        uint256 redeemResult = ltv.redeemCollateral(maxRedeemCollateral, user, user);

        uint256 finalAmountOfAssets = checkCollateralAssets - redeemResult;

        // The first rule must be strictly followed since maxSafeLTV = 90%.
        // borrowAssets * collateralPrice / collateralAssets * collateralPrice should be <= 0.9
        assertGe(finalAmountOfAssets, min);
    }
}
