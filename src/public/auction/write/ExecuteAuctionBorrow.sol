// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DeltaAuctionState} from "src/structs/state_transition/DeltaAuctionState.sol";
import {AuctionApplyDeltaState} from "src/state_transition/AuctionApplyDeltaState.sol";
import {GetAuctionStateReader} from "src/state_reader/GetAuctionStateReader.sol";
import {PreviewExecuteAuctionBorrow} from "src/public/auction/read/PreviewExecuteAuctionBorrow.sol";

/**
 * @title ExecuteAuctionBorrow
 * @notice This contract contains execute auction borrow function implementation.
 */
abstract contract ExecuteAuctionBorrow is PreviewExecuteAuctionBorrow, GetAuctionStateReader, AuctionApplyDeltaState {
    /**
     * @dev see IAuctionModule.executeAuctionBorrow
     */
    function executeAuctionBorrow(int256 deltaUserBorrowAssets)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256)
    {
        DeltaAuctionState memory deltaState =
            _previewExecuteAuctionBorrow(deltaUserBorrowAssets, auctionStateToData(getAuctionState()));
        applyDeltaState(deltaState);

        return deltaState.deltaUserCollateralAssets;
    }
}
