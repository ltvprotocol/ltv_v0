// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit, BaseTestInitWithSpecificDecimals} from "test/utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MaxWithdrawExceedsBalanceTest is BaseTest {
    using SafeERC20 for IERC20;

    address internal user = address(42);

    function test_maxWithdrawExceedsBalance() public {
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
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            maxGrowthFeeDividend: 0,
            maxGrowthFeeDivider: 1,
            collateralPrice: 2111111111111111111,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 0,
            maxDeleverageFeeDivider: 1,
            zeroAddressTokens: 10707579638052243058
        });

        initializeTest(init);

        vm.prank(address(0));
        IERC20(address(ltv)).safeTransfer(user, 3352157413899479141);
        vm.startPrank(user);
        ltv.withdraw(ltv.maxWithdraw(user), user, user);
    }

    function test_maxWithdrawExceedsBalanceTokenPrecision() public {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 6521138273291328569082,
            futureCollateral: 321885370397016172778916847147598154,
            auctionReward: -3218853703970161727789168471476025,
            startAuction: 998,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 657495789486773112842653646895308714,
            borrowAssets: 8311060254322744473141,
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            maxGrowthFeeDividend: 0,
            maxGrowthFeeDivider: 1,
            collateralPrice: 2025919433756216000,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 0,
            maxDeleverageFeeDivider: 1,
            zeroAddressTokens: 4846916111069950582657841262132135
        });

        BaseTestInitWithSpecificDecimals memory initWithSpecificDecimals =
            BaseTestInitWithSpecificDecimals({baseTestInit: init, collateralTokenDecimals: 20, borrowTokenDecimals: 6});

        initializeTestWithSpecificDecimals(initWithSpecificDecimals);

        ltv.setLastSeenTokenPrice(1020044);

        vm.startPrank(address(0));
        IERC20(address(ltv)).safeTransfer(user, 262151075048083137832424007708372);
        vm.stopPrank();

        vm.startPrank(user);
        ltv.withdrawCollateral(ltv.maxWithdrawCollateral(user), user, user);
    }
}
