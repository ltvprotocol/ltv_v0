// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/reads/IAuctionRead.sol";
import "../../interfaces/IModules.sol";

import "../../states/readers/ModulesAddressStateReader.sol";
import "../../states/readers/ApplicationStateReader.sol";

abstract contract AuctionRead is ApplicationStateReader, ModulesAddressStateReader {

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        StateRepresentationStruct memory stateRepresentation = getStateRepresentation();
        address auctionReadAddr = IModules(getModules()).auctionRead();
        return IAuctionRead(auctionReadAddr).previewExecuteAuctionBorrow(deltaUserBorrowAssets, stateRepresentation);
    }

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        StateRepresentationStruct memory stateRepresentation = getStateRepresentation();
        address auctionReadAddr = IModules(getModules()).auctionRead();
        return IAuctionRead(auctionReadAddr).previewExecuteAuctionCollateral(deltaUserCollateralAssets, stateRepresentation);
    }

}