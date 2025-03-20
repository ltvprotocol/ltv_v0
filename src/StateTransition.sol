// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./State.sol";
import "./Structs.sol";

abstract contract StateTransition is State {
    
    event StateUpdated(
        int256 oldFutureBorrowAssets,
        int256 oldFutureCollateralAssets,
        int256 oldFutureRewardBorrowAssets,
        int256 oldFutureRewardCollateralAssets,
        uint256 oldStartAuction,
        int256 newFutureBorrowAssets,
        int256 newFutureCollateralAssets,
        int256 newFutureRewardBorrowAssets,
        int256 newFutureRewardCollateralAssets,
        uint256 newStartAuction
    );

    function applyStateTransition(NextState memory nextState) internal {

        // TODO: think about Up and Down

        int256 oldFutureBorrowAssets = futureBorrowAssets;
        int256 oldFutureCollateralAssets = futureCollateralAssets;
        int256 oldFutureRewardBorrowAssets = futureRewardBorrowAssets;
        int256 oldFutureRewardCollateralAssets = futureRewardCollateralAssets;
        uint256 oldStartAuction = startAuction;


        futureBorrowAssets = nextState.futureBorrow * 1e18 / int(getPriceBorrowOracle());
        futureCollateralAssets = nextState.futureCollateral * 1e18 / int(getPriceCollateralOracle());
        futureRewardBorrowAssets = nextState.futureRewardBorrow * 1e18 / int(getPriceBorrowOracle());
        futureRewardCollateralAssets = nextState.futureRewardCollateral * 1e18 / int(getPriceCollateralOracle());

        if (nextState.merge) {
            startAuction = nextState.startAuction;
        }

        emit StateUpdated(
            oldFutureBorrowAssets,
            oldFutureCollateralAssets,
            oldFutureRewardBorrowAssets,
            oldFutureRewardCollateralAssets,
            oldStartAuction,
            futureBorrowAssets,
            futureCollateralAssets,
            futureRewardBorrowAssets,
            futureRewardCollateralAssets,
            startAuction
        );
    }

}
