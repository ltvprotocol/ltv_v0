// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {BaseTest, BaseTestInit} from "../../utils/BaseTest.t.sol";
import {Constants} from "../../../src/Constants.sol";
import "forge-std/console.sol";

contract MaxWithdrawExceedsBalanceTest is BaseTest {
    address internal user;

    function setUp() public {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 614238717158333782,
            futureCollateral: 290955181811842320,
            auctionReward: -2909551818118423,
            startAuction: 1000,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 20000000000000000000,
            borrowAssets: 31508500196998395718,
            maxSafeLTV: 9 * 10 ** 17,
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 0,
            collateralPrice: 2111111111111111111,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 0,
            zeroAddressTokens: 10707579638052243058
        });

        initializeTest(init);

        user = address(6);
        vm.prank(address(0));
        ltv.transfer(user, 3352157413899479141);
    }

    function test_maxWithdrawExceedsBalance() public {
        console.log("real collateral", ltv.getRealCollateralAssets(false));
        console.log("real borrow", ltv.getRealBorrowAssets(false));
        console.log("future collateral", ltv.futureCollateralAssets());
        console.log("future borrow", ltv.futureBorrowAssets());
        console.log("future reward collateral", ltv.futureRewardCollateralAssets());
        console.log("future reward borrow", ltv.futureRewardBorrowAssets());
        console.log("total assets", ltv.totalAssets());
        console.log("start auction", ltv.startAuction());
        console.log("block number", block.number);
        console.log("total supply", ltv.totalSupply());
        vm.startPrank(user);
        ltv.withdraw(ltv.maxWithdraw(user), user, user);
    }
}
