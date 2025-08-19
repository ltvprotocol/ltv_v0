// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteAuctionBorrow} from "src/public/auction/write/ExecuteAuctionBorrow.sol";
import {ExecuteAuctionCollateral} from "src/public/auction/write/ExecuteAuctionCollateral.sol";

contract AuctionModule is ExecuteAuctionBorrow, ExecuteAuctionCollateral {}
