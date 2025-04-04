// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./State.sol";
import "./Structs.sol";
import './Constants.sol';

abstract contract StateTransition is State {
    using sMulDiv for int256;

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
        int256 oldFutureBorrowAssets = futureBorrowAssets;
        int256 oldFutureCollateralAssets = futureCollateralAssets;
        int256 oldFutureRewardBorrowAssets = futureRewardBorrowAssets;
        int256 oldFutureRewardCollateralAssets = futureRewardCollateralAssets;
        uint256 oldStartAuction = startAuction;


        // Here we have conflict between HODLer and Future auction executor. Round in favor of HODLer

        futureBorrowAssets = nextState.futureBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(getPriceBorrowOracle()));
        futureCollateralAssets = nextState.futureCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(getPriceCollateralOracle()));
        futureRewardBorrowAssets = nextState.futureRewardBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(getPriceBorrowOracle()));
        futureRewardCollateralAssets = nextState.futureRewardCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(getPriceCollateralOracle()));

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
