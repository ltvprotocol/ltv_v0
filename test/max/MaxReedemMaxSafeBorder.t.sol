pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "../utils/BaseTest.t.sol";
import {Constants} from "../../src/Constants.sol";

contract MaxReedemMaxSafeBorderTest is BaseTest {
    address internal user;

    function test_maxRedeemAtMaxSafeLTVBorder(uint256 borrowAssets) public {
        uint256 checkBorrowAssets = bound(borrowAssets, 0, 90 * 10 ** 18);

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
            collateralAssets: uint256((100 * (10 ** 19)) / uint256(42)),
            borrowAssets: checkBorrowAssets,
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
        uint256 maxRedeem = ltv.maxRedeem(user);

        vm.startPrank(user);
        uint256 redeemResult = ltv.redeem(maxRedeem, user, user);

        uint256 finalAmountOfAssets = checkBorrowAssets + redeemResult;

        assertLe(finalAmountOfAssets, 90 * 10 ** 18);
    }
}
