// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILTV} from "../../src/interfaces/ILTV.sol";
import {Test} from "forge-std/Test.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";

struct FutureExecutorInvariantState {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
}

contract FutureExecutorInvariant is Test {
    FutureExecutorInvariantState public futureExecutorInvariantState;

    function cacheFutureExecutorInvariantState(ILTV ltv) internal {
        futureExecutorInvariantState = getFutureExecutorInvariantState(ltv);
    }

    function getFutureExecutorInvariantState(ILTV ltv) internal view returns (FutureExecutorInvariantState memory) {
        return FutureExecutorInvariantState({
            futureBorrowAssets: ltv.futureBorrowAssets(),
            futureCollateralAssets: ltv.futureCollateralAssets(),
            futureRewardBorrowAssets: ltv.futureRewardBorrowAssets(),
            futureRewardCollateralAssets: ltv.futureRewardCollateralAssets()
        });
    }

    function abs(int256 a) internal pure returns (int256) {
        return a < 0 ? -a : a;
    }

    function _checkFutureExecutorInvariantWithCachedState(ILTV ltv) internal view {
        int256 collateralPrice = int256(IOracleConnector(address(ltv.oracleConnector())).getPriceCollateralOracle());
        int256 borrowPrice = int256(IOracleConnector(address(ltv.oracleConnector())).getPriceBorrowOracle());

        FutureExecutorInvariantState memory auctionState = getFutureExecutorInvariantState(ltv);

        int256 oldReward = (
            futureExecutorInvariantState.futureBorrowAssets + futureExecutorInvariantState.futureRewardBorrowAssets
        )
            - (
                futureExecutorInvariantState.futureCollateralAssets
                    + futureExecutorInvariantState.futureRewardCollateralAssets
            ) * collateralPrice / borrowPrice;

        int256 newReward = (auctionState.futureBorrowAssets + auctionState.futureRewardBorrowAssets)
            - (auctionState.futureCollateralAssets + auctionState.futureRewardCollateralAssets) * collateralPrice
                / borrowPrice + 1;

        assertGe(oldReward, 0, "oldReward is not positive");
        assertGe(newReward, 0, "newReward is not positive");

        assertGe(
            abs(futureExecutorInvariantState.futureCollateralAssets) * newReward,
            abs(auctionState.futureCollateralAssets) * oldReward,
            "New reward is not greater than old reward, collateral measure"
        );
        assertGe(
            abs(futureExecutorInvariantState.futureBorrowAssets) * newReward,
            abs(auctionState.futureBorrowAssets) * oldReward,
            "New reward is not greater than old reward, borrow measure"
        );
    }
}
