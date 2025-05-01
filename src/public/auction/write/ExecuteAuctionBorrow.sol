// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/auction/read/PreviewExecuteAuctionBorrow.sol';
import 'src/states/LTVState.sol';
import 'src/state_transition/AuctionApplyDeltaState.sol';

contract ExecuteAuctionBorrow is PreviewExecuteAuctionBorrow, LTVState, AuctionApplyDeltaState {
    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = _previewExecuteAuctionBorrow(
            deltaUserBorrowAssets,
            auctionStateToData(getAuctionState())
        );
        applyDeltaState(deltaState);

        return deltaState.deltaUserCollateralAssets;
    }
} 