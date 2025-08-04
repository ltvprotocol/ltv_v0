// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {BaseTest, BaseTestInit} from "../../utils/BaseTest.t.sol";
import {Constants} from "../../../src/Constants.sol";

contract NearZeroAuctionFinalRoundingTest is BaseTest {
    address internal user;

    function setUp() public {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: -3000000,
            futureCollateral: -1421099,
            auctionReward: 30000,
            startAuction: 0,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 1894736842,
            borrowAssets: 3000000000,
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

    function test_nearZeroAuctionFinalRounding() public {
        uint256 initialTotalAssets = ltv.totalAssets();
        uint256 initialTotalSupply = ltv.convertToShares(initialTotalAssets);
        vm.startPrank(user);
        ltv.deposit(0, user);
        assertEq(ltv.futureCollateralAssets(), 0);
        assertEq(ltv.futureBorrowAssets(), 0);
        assertGe(
            ltv.totalAssets() * initialTotalSupply, initialTotalAssets * ltv.totalSupply(), "Token price became smaller"
        );
    }
}
