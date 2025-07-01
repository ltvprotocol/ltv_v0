// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData, Constants} from "../utils/BaseTest.t.sol";
import "../../src/utils/MulDiv.sol";

contract AuctionTestCommon is BaseTest {
    using sMulDiv for int256;

    struct AuctionState {
        int256 futureBorrowAssets;
        int256 futureCollateralAssets;
        int256 futureRewardBorrowAssets;
        int256 futureRewardCollateralAssets;
        int256 totalCollateral;
        int256 totalBorrow;
    }

    function getAuctionState() internal view returns (AuctionState memory) {
        return AuctionState({
            futureBorrowAssets: ltv.futureBorrowAssets(),
            futureCollateralAssets: ltv.futureCollateralAssets(),
            futureRewardBorrowAssets: ltv.futureRewardBorrowAssets(),
            futureRewardCollateralAssets: ltv.futureRewardCollateralAssets(),
            totalCollateral: int256(ltv.getRealCollateralAssets(true)) + ltv.futureRewardCollateralAssets()
                + ltv.futureCollateralAssets(),
            totalBorrow: int256(ltv.getRealBorrowAssets(true)) + ltv.futureRewardBorrowAssets() + ltv.futureBorrowAssets()
        });
    }

    function abs(int256 a) internal pure returns (int256) {
        return a < 0 ? -a : a;
    }

    function checkFutureExecutorProfit(AuctionState memory initialAuctionState) internal view {
        AuctionState memory auctionState = getAuctionState();
        int256 collateralPrice = int256(oracle.getAssetPrice(address(collateralToken)));
        int256 borrowPrice = int256(oracle.getAssetPrice(address(borrowToken)));

        int256 oldReward = (initialAuctionState.futureBorrowAssets + initialAuctionState.futureRewardBorrowAssets)
            - (initialAuctionState.futureCollateralAssets + initialAuctionState.futureRewardCollateralAssets).mulDivUp(
                collateralPrice, borrowPrice
            );

        int256 newReward = (auctionState.futureBorrowAssets + auctionState.futureRewardBorrowAssets)
            - (auctionState.futureCollateralAssets + auctionState.futureRewardCollateralAssets).mulDivDown(
                collateralPrice, borrowPrice
            );

        assertGe(oldReward, 0, "oldReward is not positive");

        assertGe(newReward, 0, "newReward is not positive");

        assertGe(
            abs(initialAuctionState.futureBorrowAssets) * newReward, abs(auctionState.futureBorrowAssets) * oldReward
        );

        // if futureBorrowAssets or futureCollateralAssets is 0, then the other one has to be 0 too
        assertTrue(
            (auctionState.futureBorrowAssets != 0 && auctionState.futureCollateralAssets != 0)
                || (
                    auctionState.futureBorrowAssets == 0 && auctionState.futureCollateralAssets == 0
                        && auctionState.futureRewardBorrowAssets == 0 && auctionState.futureRewardCollateralAssets == 0
                )
        );

        assertEq(auctionState.totalCollateral, initialAuctionState.totalCollateral);
    }

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
        ltv.setMinProfitLTV(uint128(0));
        ltv.setMaxSafeLTV(uint128(Constants.LTV_DIVIDER));
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
