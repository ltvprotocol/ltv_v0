// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit, BaseTestInitWithSpecificDecimals} from "test/utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract DecimalsPrecision is BaseTest {
    using SafeERC20 for IERC20;

    address internal user = address(42);

    function setUp() public {
        BaseTestInitWithSpecificDecimals memory init = BaseTestInitWithSpecificDecimals(
            BaseTestInit({
                owner: address(1),
                guardian: address(2),
                governor: address(3),
                emergencyDeleverager: address(4),
                feeCollector: address(5),
                futureBorrow: 1,
                futureCollateral: 41,
                auctionReward: -1,
                startAuction: 2,
                collateralSlippage: 10 ** 16,
                borrowSlippage: 10 ** 16,
                maxTotalAssetsInUnderlying: type(uint128).max,
                collateralAssets: 722398864988594198841262830988588053,
                borrowAssets: 10879306567575297447548,
                maxSafeLtvDividend: 9,
                maxSafeLtvDivider: 10,
                minProfitLtvDividend: 5,
                minProfitLtvDivider: 10,
                targetLtvDividend: 75,
                targetLtvDivider: 100,
                maxGrowthFeeDividend: 0,
                maxGrowthFeeDivider: 1,
                collateralPrice: 2007741009976464800,
                borrowPrice: 1000000000000000000,
                maxDeleverageFeeDividend: 0,
                maxDeleverageFeeDivider: 1,
                zeroAddressTokens: 3600037169107918208239293372608589
            }),
            20,
            6
        );

        initializeTestWithSpecificDecimals(init);

        ltv.setLastSeenTokenPrice(1007205);
        user = address(6);
        vm.prank(address(0));
        IERC20(address(ltv)).safeTransfer(user, 471123328725870874475296611342);
    }

    function test_auctionInvariant() public {
        vm.startPrank(user);
        ltv.redeem(ltv.balanceOf(user), user, user);
        vm.stopPrank();

        assertLt(ltv.futureCollateralAssets(), 0);
        assertEq(ltv.futureRewardCollateralAssets(), 0);
    }
}
