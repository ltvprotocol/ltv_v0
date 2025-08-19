// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

abstract contract AuctionWrite is LTVState, CommonWrite {
    function executeAuctionBorrow(int256 deltaFutureBorrowAssets) external returns (int256) {
        _delegate(address(modules.auctionModule()), abi.encode(deltaFutureBorrowAssets));
    }

    function executeAuctionCollateral(int256 deltaFutureCollateralAssets) external returns (int256) {
        _delegate(address(modules.auctionModule()), abi.encode(deltaFutureCollateralAssets));
    }
}
