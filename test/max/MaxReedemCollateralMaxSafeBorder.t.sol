// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "test/utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MaxReedemCollateralMaxSafeBorderTest is BaseTest {
    using SafeERC20 for IERC20;

    address internal user;

    function test_maxRedeemCollateralAtmaxSafeLtvBorder(uint256 collateralAssets) public {
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
            maxSafeLtvDividend: 9, // 90%
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
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
        IERC20(address(ltv)).safeTransfer(user, 25 * 10 ** 18);

        user = address(6);
        vm.startPrank(user);
        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);

        vm.startPrank(user);
        uint256 redeemResult = ltv.redeemCollateral(maxRedeemCollateral, user, user);

        uint256 finalAmountOfAssets = checkCollateralAssets - redeemResult;

        // The first rule must be strictly followed since maxSafeLtv = 90%.
        // borrowAssets * collateralPrice / collateralAssets * collateralPrice should be <= 0.9
        assertGe(finalAmountOfAssets, min);
    }
}
