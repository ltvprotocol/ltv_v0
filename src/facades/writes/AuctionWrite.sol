// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract AuctionWrite is ModulesAddressStateReader, CommonWrite {
    function executeAuctionBorrow(int256 deltaFutureBorrowAssets) external returns (int256) {
        _delegate(getModules().auctionWrite(), abi.encode(deltaFutureBorrowAssets));
    }

    function executeAuctionCollateral(int256 deltaFutureCollateralAssets) external returns (int256) {
        _delegate(getModules().auctionWrite(), abi.encode(deltaFutureCollateralAssets));
    }
}