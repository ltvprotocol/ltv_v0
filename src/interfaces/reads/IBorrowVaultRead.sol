// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { StateRepresentationStruct } from "../../structs/StateRepresentationStruct.sol";

interface IBorrowVaultRead {
    function previewDeposit(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewWithdraw(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewMint(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewRedeem(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxDeposit(address receiver, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxWithdraw(address owner, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxMint(address receiver, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxRedeem(address owner, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function convertToShares(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function convertToAssets(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function totalAssets(StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function _totalAssets(bool isDeposit, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);
} 