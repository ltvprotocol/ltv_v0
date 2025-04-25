// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {StateRepresentationStruct} from '../../structs/StateRepresentationStruct.sol';
import 'src/Structs2.sol';

interface ILowLevelRebalanceRead {
    function previewLowLevelRebalanceShares(
        int256 deltaShares,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceBorrow(
        int256 deltaBorrowAssets,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceCollateral(
        int256 deltaCollateralAssets,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256, int256);

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256, int256);

    function maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesState memory stateRepresentation) external view returns (int256);

    function maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory stateRepresentation) external view returns (int256);

    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory stateRepresentation) external view returns (int256);
}
