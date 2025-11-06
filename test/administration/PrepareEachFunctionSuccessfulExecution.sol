// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest} from "../utils/BaseTest.t.sol";

contract PrepareEachFunctionSuccessfulExecution is BaseTest {
    function prepareEachFunctionSuccessfulExecution(address user) public {
        uint256 amount = ltv.balanceOf(address(0));
        deal(address(ltv), address(0), amount / 2);
        deal(address(ltv), address(user), amount - amount / 2);
        vm.prank(address(0));
        ltv.approve(user, type(uint128).max);

        deal(address(collateralToken), user, type(uint128).max);
        deal(address(borrowToken), user, type(uint128).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint128).max);
        borrowToken.approve(address(ltv), type(uint128).max);
        vm.stopPrank();

        ltv.setFutureBorrowAssets(-10000);
        ltv.setFutureCollateralAssets(-10000);
        ltv.setFutureRewardBorrowAssets(100);
    }
}
