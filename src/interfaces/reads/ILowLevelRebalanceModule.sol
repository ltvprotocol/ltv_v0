// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";
import {MaxLowLevelRebalanceSharesState} from "src/structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import {MaxLowLevelRebalanceBorrowStateData} from "src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";
import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";

interface ILowLevelRebalanceModule {
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
    ) external view returns (int256, int256);

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    function maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesState memory stateRepresentation)
        external
        view
        returns (int256);

    function maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory stateRepresentation)
        external
        view
        returns (int256);

    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory stateRepresentation)
        external
        view
        returns (int256);
}
