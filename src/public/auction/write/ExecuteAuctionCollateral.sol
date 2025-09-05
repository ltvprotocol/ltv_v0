// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DeltaAuctionState} from "src/structs/state_transition/DeltaAuctionState.sol";
import {AuctionApplyDeltaState} from "src/state_transition/AuctionApplyDeltaState.sol";
import {GetAuctionStateReader} from "src/state_reader/GetAuctionStateReader.sol";
import {PreviewExecuteAuctionCollateral} from "src/public/auction/read/PreviewExecuteAuctionCollateral.sol";

/**
 * @title ExecuteAuctionCollateral
 * @notice This contract contains execute auction collateral function implementation.
 */
abstract contract ExecuteAuctionCollateral is
    PreviewExecuteAuctionCollateral,
    GetAuctionStateReader,
    AuctionApplyDeltaState
{
    /**
     * @dev see IAuctionModule.executeAuctionCollateral
     */
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
