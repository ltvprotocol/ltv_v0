// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { StateRepresentationStruct } from "../../structs/StateRepresentationStruct.sol";

interface IAuctionRead {

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (int256);


    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (int256);

}