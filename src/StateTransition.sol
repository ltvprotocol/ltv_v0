// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./State.sol";
import "./Structs.sol";

abstract contract StateTransition is State {

    function applyStateTransition(NextState memory nextState) internal {

        // TODO: think about Up and Down

        futureBorrowAssets = nextState.futureBorrow * 1e18 / int(getPriceBorrowOracle()) ;
        futureCollateralAssets = nextState.futureCollateral * 1e18 / int(getPriceCollateralOracle());
        futureRewardBorrowAssets = nextState.futureRewardBorrow * 1e18 / int(getPriceBorrowOracle());
        futureRewardCollateralAssets = nextState.futureRewardCollateral * 1e18 / int(getPriceCollateralOracle());

        if (nextState.merge) {
            startAuction = nextState.startAuction;
        }
    }

}
