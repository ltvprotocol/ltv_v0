// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/auction/read/PreviewExecuteAuctionCollateral.sol";
import "src/state_reader/GetAuctionStateReader.sol";
import "src/state_transition/AuctionApplyDeltaState.sol";

abstract contract ExecuteAuctionCollateral is
    PreviewExecuteAuctionCollateral,
    GetAuctionStateReader,
    AuctionApplyDeltaState
{
    function executeAuctionCollateral(int256 deltaUserCollateralAssets)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256)
    {
        DeltaAuctionState memory deltaState =
            _previewExecuteAuctionCollateral(deltaUserCollateralAssets, auctionStateToData(getAuctionState()));
        applyDeltaState(deltaState);

        return deltaState.deltaUserBorrowAssets;
    }
}
