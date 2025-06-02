// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";
import "../Constants.sol";
import "../utils/MulDiv.sol";
import "../structs/state_transition/NextStateData.sol";
import "src/events/IStateUpdateEvent.sol";

abstract contract VaultStateTransition is LTVState, IStateUpdateEvent {
    using sMulDiv for int256;

    function applyStateTransition(NextStateData memory nextStateData) internal {
        int256 oldFutureBorrowAssets = futureBorrowAssets;
        int256 oldFutureCollateralAssets = futureCollateralAssets;
        int256 oldFutureRewardBorrowAssets = futureRewardBorrowAssets;
        int256 oldFutureRewardCollateralAssets = futureRewardCollateralAssets;
        uint256 oldStartAuction = startAuction;

        // Here we have conflict between HODLer and Future auction executor. Round in favor of HODLer

        futureBorrowAssets = nextStateData.nextState.futureBorrow.mulDivDown(
            int256(Constants.ORACLE_DIVIDER), int256(nextStateData.borrowPrice)
        );
        futureCollateralAssets = nextStateData.nextState.futureCollateral.mulDivUp(
            int256(Constants.ORACLE_DIVIDER), int256(nextStateData.collateralPrice)
        );
        futureRewardBorrowAssets = nextStateData.nextState.futureRewardBorrow.mulDivDown(
            int256(Constants.ORACLE_DIVIDER), int256(nextStateData.borrowPrice)
        );
        futureRewardCollateralAssets = nextStateData.nextState.futureRewardCollateral.mulDivUp(
            int256(Constants.ORACLE_DIVIDER), int256(nextStateData.collateralPrice)
        );

        if (nextStateData.nextState.merge) {
            startAuction = nextStateData.nextState.startAuction;
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
