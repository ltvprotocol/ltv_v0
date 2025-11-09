// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "../../structs/state/low_level/preview/PreviewLowLevelRebalanceState.sol";
import {MaxLowLevelRebalanceSharesState} from "../../structs/state/low_level/max/MaxLowLevelRebalanceSharesState.sol";
import {MaxLowLevelRebalanceBorrowStateData} from
    "../../structs/state/low_level/max/MaxLowLevelRebalanceBorrowStateData.sol";
import {MaxLowLevelRebalanceCollateralStateData} from
    "../../structs/state/low_level/max/MaxLowLevelRebalanceCollateralStateData.sol";

/**
 * @title ILowLevelRebalanceModule
 * @notice Interface defining all read functions for the low level rebalance module in the LTV protocol
 * @dev This interface contains read functions for the low level rebalance part of the LTV protocol
 */
interface ILowLevelRebalanceModule {
    /**
     * @dev Module function for ILTV.previewLowLevelRebalanceShares. Also receives cached state for subsequent calculations.
     */
    function previewLowLevelRebalanceShares(
        int256 deltaShares,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    /**
     * @dev Module function for ILTV.previewLowLevelRebalanceBorrow. Also receives cached state for subsequent calculations.
     */
    function previewLowLevelRebalanceBorrow(
        int256 deltaBorrowAssets,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    /**
     * @dev Module function for ILTV.previewLowLevelRebalanceCollateral. Also receives cached state for subsequent calculations.
     */
    function previewLowLevelRebalanceCollateral(
        int256 deltaCollateralAssets,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    /**
     * @dev Module function for ILTV.previewLowLevelRebalanceBorrowHint. Also receives cached state for subsequent calculations.
     */
    function previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    /**
     * @dev Module function for ILTV.previewLowLevelRebalanceCollateralHint. Also receives cached state for subsequent calculations.
     */
    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory stateRepresentation
    ) external view returns (int256, int256);

    /**
     * @dev Module function for ILTV.maxLowLevelRebalanceShares. Also receives cached state for subsequent calculations.
     */
    function maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesState memory stateRepresentation)
        external
        view
        returns (int256);

    /**
     * @dev Module function for ILTV.maxLowLevelRebalanceBorrow. Also receives cached state for subsequent calculations.
     */
    function maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory stateRepresentation)
        external
        view
        returns (int256);

    /**
     * @dev Module function for ILTV.maxLowLevelRebalanceCollateral. Also receives cached state for subsequent calculations.
     */
    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory stateRepresentation)
        external
        view
        returns (int256);
}
