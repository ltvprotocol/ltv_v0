// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/auction/write/ExecuteAuctionBorrow.sol";
import "src/public/auction/write/ExecuteAuctionCollateral.sol";

contract AuctionModule is ExecuteAuctionBorrow, ExecuteAuctionCollateral {}
