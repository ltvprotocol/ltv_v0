// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract AuctionWrite is ModulesAddressStateReader, CommonWrite {

    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256) {
        address auctionWriteAddr = IModules(getModules()).auctionWrite();
        return makeDelegateInt256(abi.encodeWithSignature("executeAuctionBorrow(int256)", deltaUserBorrowAssets), auctionWriteAddr);
    }

    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256) {
        address auctionWriteAddr = IModules(getModules()).auctionWrite();
        return makeDelegateInt256(abi.encodeWithSignature("executeAuctionCollateral(int256)", deltaUserCollateralAssets), auctionWriteAddr);
    }

}