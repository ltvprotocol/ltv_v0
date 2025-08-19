// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {BaseTest, BaseTestInit} from "test/utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MaxWithdrawExceedsBalanceTest is BaseTest {
    using SafeERC20 for IERC20;

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

        user = address(6);
        vm.prank(address(0));
        IERC20(address(ltv)).safeTransfer(user, 3352157413899479141);
    }

    function test_maxWithdrawExceedsBalance() public {
        vm.startPrank(user);
        ltv.withdraw(ltv.maxWithdraw(user), user, user);
    }
}
