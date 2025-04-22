// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../read/PreviewAuction.sol';
import 'src/states/LTVState.sol';
import 'src/state_transition/AuctionApplyDeltaState.sol';

contract ExecuteAuction is PreviewAuction, LTVState, AuctionApplyDeltaState {
    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = _previewExecuteAuctionCollateral(
            deltaUserCollateralAssets,
            auctionStateToAuctionData(getAuctionState())
        );
        applyDeltaState(deltaState);

        return deltaState.deltaUserBorrowAssets;
    }

    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToAuctionData(getAuctionState()));
        applyDeltaState(deltaState);

        return deltaState.deltaUserCollateralAssets;
    }
}
