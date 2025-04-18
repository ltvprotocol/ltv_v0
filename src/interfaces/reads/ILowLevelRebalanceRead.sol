// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {StateRepresentationStruct} from '../../structs/StateRepresentationStruct.sol';

interface ILowLevelRebalanceRead {
    function previewLowLevelRebalanceShares(
        int256 deltaShares,
        StateRepresentationStruct memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceBorrow(
        int256 deltaBorrowAssets,
        StateRepresentationStruct memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceCollateral(
        int256 deltaCollateralAssets,
        StateRepresentationStruct memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        StateRepresentationStruct memory stateRepresentation
    ) external view returns (int256, int256, int256);

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        StateRepresentationStruct memory stateRepresentation
    ) external view returns (int256, int256, int256);

    function maxLowLevelRebalanceShares(StateRepresentationStruct memory stateRepresentation) external view returns (int256);

    function maxLowLevelRebalanceBorrow(StateRepresentationStruct memory stateRepresentation) external view returns (int256);

    function maxLowLevelRebalanceCollateral(StateRepresentationStruct memory stateRepresentation) external view returns (int256);
}
