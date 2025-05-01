// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/auction/read/PreviewExecuteAuctionCollateral.sol';
import 'src/states/LTVState.sol';
import 'src/state_transition/AuctionApplyDeltaState.sol';

contract ExecuteAuctionCollateral is PreviewExecuteAuctionCollateral, LTVState, AuctionApplyDeltaState {
    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = _previewExecuteAuctionCollateral(
            deltaUserCollateralAssets,
            auctionStateToData(getAuctionState())
        );
        applyDeltaState(deltaState);

        return deltaState.deltaUserBorrowAssets;
    }
} 