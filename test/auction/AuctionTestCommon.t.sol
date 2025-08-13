// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData, Constants} from "../utils/BaseTest.t.sol";
import {FutureExecutorInvariant, FutureExecutorInvariantState} from "./FutureExecutorInvariant.t.sol";
import "../../src/utils/MulDiv.sol";

contract AuctionTestCommon is BaseTest, FutureExecutorInvariant {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function prepareUser(address user) public {
        deal(address(collateralToken), user, type(uint256).max);
        deal(address(borrowToken), user, type(uint256).max);

        vm.startPrank(user);
        collateralToken.approve(address(ltv), type(uint256).max);
        borrowToken.approve(address(ltv), type(uint256).max);
        vm.stopPrank();
    }

    function prepareWithdrawAuction(uint128 amount, address governor, address user) public {
        prepareWithdrawAuctionWithCustomCollateralPrice(
            amount, governor, user, oracle.getAssetPrice(address(collateralToken))
        );
    }

    function prepareWithdrawAuctionWithCustomCollateralPrice(
        uint128 amount,
        address governor,
        address user,
        uint256 collateralPrice
    ) public {
        oracle.setAssetPrice(address(collateralToken), collateralPrice);

        vm.startPrank(governor);
        ltv.setMinProfitLTV(0, 1);
        ltv.setMaxSafeLTV(1, 1);
        vm.stopPrank();

        vm.startPrank(user);
        deal(address(collateralToken), user, type(uint256).max);
        collateralToken.approve(address(ltv), type(uint256).max);
        ltv.depositCollateral(amount, user);

        ltv.executeLowLevelRebalanceShares(0);

        ltv.setFutureBorrowAssets(-int256(uint256(amount)));
        ltv.setFutureCollateralAssets(
            (-int256(uint256(amount))).mulDivDown(
                int256(oracle.getAssetPrice(address(borrowToken))), int256(collateralPrice)
            )
        );

        ltv.setFutureRewardBorrowAssets(int256(uint256(amount / 100)));
        deal(address(collateralToken), user, 0);
        vm.stopPrank();
    }

    function prepareDepositAuctionWithCustomCollateralPrice(uint128 amount, uint256 collateralPrice, address owner)
        public
    {
        deal(address(collateralToken), owner, type(uint128).max);

        vm.startPrank(owner);
        collateralToken.approve(address(ltv), type(uint128).max);
        ltv.executeLowLevelRebalanceShares(int256(uint256(amount)));

        oracle.setAssetPrice(address(collateralToken), collateralPrice);
        ltv.setFutureBorrowAssets(int256(uint256(amount)));
        ltv.setFutureCollateralAssets(
            int256(uint256(amount)).mulDivDown(
                int256(oracle.getAssetPrice(address(borrowToken))), int256(collateralPrice)
            )
        );
        ltv.setFutureRewardCollateralAssets(
            (-int256(uint256(amount / 100))).mulDivDown(
                int256(oracle.getAssetPrice(address(borrowToken))), int256(collateralPrice)
            )
        );
    }

    function prepareDepositAuction(uint128 amount, address owner) public {
        prepareDepositAuctionWithCustomCollateralPrice(amount, oracle.getAssetPrice(address(collateralToken)), owner);
    }
}
