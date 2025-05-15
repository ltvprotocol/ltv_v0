// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/reads/IAuctionRead.sol";
import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";

abstract contract AuctionRead is LTVState {

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        return modules.auctionRead().previewExecuteAuctionBorrow(deltaUserBorrowAssets, getAuctionState());
    }

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        return modules.auctionRead().previewExecuteAuctionCollateral(deltaUserCollateralAssets, getAuctionState());
    }

}