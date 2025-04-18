// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { StateRepresentationStruct } from "../../structs/StateRepresentationStruct.sol";

interface ICollateralVaultRead {
    function previewDepositCollateral(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewWithdrawCollateral(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewMintCollateral(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function previewRedeemCollateral(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxDepositCollateral(address receiver, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxWithdrawCollateral(address owner, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxMintCollateral(address receiver, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function maxRedeemCollateral(address owner, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function convertToSharesCollateral(uint256 assets, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function convertToAssetsCollateral(uint256 shares, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function totalAssetsCollateral(StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);

    function _totalAssetsCollateral(bool isDeposit, StateRepresentationStruct memory stateRepresentation)
        external
        view
        returns (uint256);
} 