// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/auction/read/PreviewExecuteAuctionBorrow.sol';
import 'src/state_transition/AuctionApplyDeltaState.sol';
import 'src/state_reader/GetAuctionStateReader.sol';

abstract contract ExecuteAuctionBorrow is PreviewExecuteAuctionBorrow, GetAuctionStateReader, AuctionApplyDeltaState {
    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external isFunctionAllowed nonReentrant returns (int256) {
        DeltaAuctionState memory deltaState = _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToData(getAuctionState()));
        applyDeltaState(deltaState);

        return deltaState.deltaUserCollateralAssets;
    }
}
