// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData, Constants} from "../utils/BaseTest.t.sol";

contract AuctionTestCommon is BaseTest {
    struct AuctionState {
        int256 futureBorrowAssets;
        int256 futureCollateralAssets;
        int256 futureRewardBorrowAssets;
        int256 futureRewardCollateralAssets;
    }

    function getAuctionState() internal view returns (AuctionState memory) {
        return AuctionState({
            futureBorrowAssets: ltv.futureBorrowAssets(),
            futureCollateralAssets: ltv.futureCollateralAssets(),
            futureRewardBorrowAssets: ltv.futureRewardBorrowAssets(),
            futureRewardCollateralAssets: ltv.futureRewardCollateralAssets()
        });
    }

    function abs(int256 a) internal pure returns (int256) {
        return a < 0 ? -a : a;
    }

    function checkFutureExecutorProfit(AuctionState memory initialAuctionState) internal view {
        AuctionState memory auctionState = getAuctionState();

        int256 oldReward = (initialAuctionState.futureBorrowAssets + initialAuctionState.futureRewardBorrowAssets)
            - (initialAuctionState.futureCollateralAssets + initialAuctionState.futureRewardCollateralAssets) * 2;

        int256 newReward = (auctionState.futureBorrowAssets + auctionState.futureRewardBorrowAssets)
            - (auctionState.futureCollateralAssets + auctionState.futureRewardCollateralAssets) * 2;

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
