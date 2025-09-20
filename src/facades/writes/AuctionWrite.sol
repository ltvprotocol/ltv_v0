// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

/**
 * @title AuctionWrite
 * @notice This contract contains all the write functions for the auction part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the auction module.
 */
abstract contract AuctionWrite is LTVState, CommonWrite {
    /**
     * @dev see ILTV.executeAuctionBorrow
     */
    function executeAuctionBorrow(int256 deltaFutureBorrowAssets) external returns (int256) {
        _delegate(address(modules.auctionModule()), abi.encode(deltaFutureBorrowAssets));
    }

    /**
     * @dev see ILTV.executeAuctionCollateral
     */
    function executeAuctionCollateral(int256 deltaFutureCollateralAssets) external returns (int256) {
        _delegate(address(modules.auctionModule()), abi.encode(deltaFutureCollateralAssets));
    }
}
