// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GetAuctionStateReader} from "src/state_reader/GetAuctionStateReader.sol";

abstract contract AuctionRead is GetAuctionStateReader {
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        return modules.auctionModule().previewExecuteAuctionBorrow(deltaUserBorrowAssets, getAuctionState());
    }

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        return modules.auctionModule().previewExecuteAuctionCollateral(deltaUserCollateralAssets, getAuctionState());
    }
}
