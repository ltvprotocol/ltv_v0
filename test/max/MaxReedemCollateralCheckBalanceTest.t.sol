// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "../utils/BaseTest.t.sol";
import {Constants} from "../../src/Constants.sol";

contract MaxReedemCollateralCheckBalanceTest is BaseTest {
    address internal user;

    function setUp() public {
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
            borrowAssets: 75 * 10 ** 18,
            maxSafeLTVDividend: 9,
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
    }

    function test_maxRedeemCollateralCheckBalance(uint256 amount) public {
        uint256 checkAmount = bound(amount, 0, 5 * 10 ** 18);

        user = address(6);
        vm.prank(address(0));
        ltv.transfer(user, checkAmount);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), checkAmount);

        uint256 maxRedeem = ltv.maxRedeemCollateral(user);

        assertEq(maxRedeem, checkAmount);

        ltv.redeemCollateral(maxRedeem, user, user);
    }
}
