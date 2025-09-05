// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteAuctionBorrow} from "src/public/auction/write/ExecuteAuctionBorrow.sol";
import {ExecuteAuctionCollateral} from "src/public/auction/write/ExecuteAuctionCollateral.sol";

/**
 * @title AuctionModule
 * @notice Auction module for LTV protocol
 */
contract AuctionModule is ExecuteAuctionBorrow, ExecuteAuctionCollateral {
    constructor() {
        _disableInitializers();
    }
}
