// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {NextStateData} from "src/structs/state_transition/NextStateData.sol";
import {LTVState} from "src/states/LTVState.sol";
import {sMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title VaultStateTransition
 * @notice contract contains functionality to apply state transition after vault calculations
 */
abstract contract VaultStateTransition is LTVState {
    using sMulDiv for int256;

    /**
     * @dev applies state transition after vault calculations
     */
    function applyStateTransition(NextStateData memory nextStateData) internal {
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

        // Because of precision loss, we can get futureCollateral assets to become zero, while futureBorrow assets is not zero.
        // In this case we assume auction is fully executed and set it to zero. We won't lose any assets since auction is considered
        // to be always profitable. In case of zeroing, all the profit goes to HODLer
        if (
            (futureBorrowAssets == 0 && futureCollateralAssets != 0)
                || (futureBorrowAssets != 0 && futureCollateralAssets == 0)
        ) {
            futureBorrowAssets = 0;
            futureCollateralAssets = 0;
            futureRewardBorrowAssets = 0;
            futureRewardCollateralAssets = 0;
            startAuction = 0;
        }
    }
}
