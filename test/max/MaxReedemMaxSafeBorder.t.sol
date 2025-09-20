// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "test/utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MaxReedemMaxSafeBorderTest is BaseTest {
    using SafeERC20 for IERC20;

    address internal user;

    function test_maxRedeemAtmaxSafeLtvBorder(uint256 borrowAssets) public {
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
        uint256 maxRedeem = ltv.maxRedeem(user);

        vm.startPrank(user);
        uint256 redeemResult = ltv.redeem(maxRedeem, user, user);

        uint256 finalAmountOfAssets = checkBorrowAssets + redeemResult;

        assertLe(finalAmountOfAssets, 90 * 10 ** 18);
    }
}
