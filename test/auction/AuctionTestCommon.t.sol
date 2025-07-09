// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData, Constants} from "../utils/BaseTest.t.sol";
import {FutureExecutorInvariant, FutureExecutorInvariantState} from "./FutureExecutorInvariant.t.sol";

contract AuctionTestCommon is BaseTest, FutureExecutorInvariant {

    function prepareUser(address user) public {
        deal(address(collateralToken), user, type(uint256).max);
        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);
        vm.stopPrank();
    }

    function prepareWithdrawAuction(uint128 amount, address governor, address user) public {
        vm.startPrank(governor);
        ltv.setMinProfitLTV(uint128(0));
        ltv.setMaxSafeLTV(uint128(Constants.LTV_DIVIDER));
        vm.stopPrank();

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint256).max);
        collateralToken.approve(address(ltv), type(uint256).max);
        ltv.depositCollateral(amount, user);

        ltv.executeLowLevelRebalanceShares(0);

        ltv.setFutureBorrowAssets(-int256(uint256(amount)));
        ltv.setFutureCollateralAssets(-int256(uint256(amount)) / 2 + (amount % 2 == 1 ? -1 : int8(0)));
        ltv.setFutureRewardBorrowAssets(int256(uint256(amount / 100)));
        deal(address(collateralToken), user, 0);
    }

    function prepareDepositAuction(uint128 amount) public {
        ltv.setFutureBorrowAssets(int256(uint256(amount)));
        ltv.setFutureCollateralAssets(int256(uint256(amount)) / 2);
        ltv.setFutureRewardCollateralAssets(-int256(uint256(amount / 200)));
    }
}
