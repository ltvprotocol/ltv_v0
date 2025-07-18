pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "../utils/BaseTest.t.sol";
import {Constants} from "../../src/Constants.sol";

contract MaxReedemCollateralMaxSafeBorderTest is BaseTest {
    address internal user;

    function test_maxRedeemCollateralAtMaxSafeLTVBorder(uint256 collateralAssets) public {
        uint256 min = uint256((100 * (10 ** 19)) / uint256(42));

        uint256 checkCollateralAssets;

        if (collateralAssets > 64 * min) {
            checkCollateralAssets = collateralAssets % 64 * min;
        } else {
            checkCollateralAssets = collateralAssets;
        }

        if (checkCollateralAssets < min) {
            checkCollateralAssets = checkCollateralAssets + min;
        } else {
            checkCollateralAssets = checkCollateralAssets;
        }

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
            maxSafeLTV: 9 * 10 ** 17, // 90%
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 0,
            collateralPrice: 42 * 10 ** 17,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 0,
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
        assertLt(finalAmountOfAssets - 60, min);
    }
}
