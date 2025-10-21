// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceStateReader} from "src/state_reader/low_level/PreviewLowLevelRebalanceStateReader.sol";
import {MaxLowLevelRebalanceSharesStateReader} from
    "src/state_reader/low_level/MaxLowLevelRebalanceSharesStateReader.sol";
import {MaxLowLevelRebalanceBorrowStateReader} from
    "src/state_reader/low_level/MaxLowLevelRebalanceBorrowStateReader.sol";
import {MaxLowLevelRebalanceCollateralStateReader} from
    "src/state_reader/low_level/MaxLowLevelRebalanceCollateralStateReader.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title LowLevelRebalanceRead
 * @notice This contract contains all the read functions for the low level rebalance part of the LTV protocol.
 * It retrieves appropriate function state and delegates all the calculations to the low level rebalance module.
 */
abstract contract LowLevelRebalanceRead is
    PreviewLowLevelRebalanceStateReader,
    MaxLowLevelRebalanceSharesStateReader,
    MaxLowLevelRebalanceBorrowStateReader,
    MaxLowLevelRebalanceCollateralStateReader,
    FacadeImplementationState
{
    /**
     * @dev see ILTV.previewLowLevelRebalanceShares
     */
    function previewLowLevelRebalanceShares(int256 deltaShares) public view returns (int256, int256) {
        return MODULES.lowLevelRebalanceModule().previewLowLevelRebalanceShares(
            deltaShares, previewLowLevelRebalanceState()
        );
    }

    /**
     * @dev see ILTV.previewLowLevelRebalanceBorrow
     */
    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        return MODULES.lowLevelRebalanceModule().previewLowLevelRebalanceBorrow(
            deltaBorrowAssets, previewLowLevelRebalanceState()
        );
    }

    /**
     * @dev see ILTV.previewLowLevelRebalanceCollateral
     */
    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        return MODULES.lowLevelRebalanceModule().previewLowLevelRebalanceCollateral(
            deltaCollateralAssets, previewLowLevelRebalanceState()
        );
    }

    /**
     * @dev see ILTV.previewLowLevelRebalanceBorrowHint
     */
    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256)
    {
        return MODULES.lowLevelRebalanceModule().previewLowLevelRebalanceBorrowHint(
            deltaBorrowAssets, isSharesPositiveHint, previewLowLevelRebalanceState()
        );
    }

    /**
     * @dev see ILTV.previewLowLevelRebalanceCollateralHint
     */
    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256)
    {
        return MODULES.lowLevelRebalanceModule().previewLowLevelRebalanceCollateralHint(
            deltaCollateralAssets, isSharesPositiveHint, previewLowLevelRebalanceState()
        );
    }

    /**
     * @dev see ILTV.maxLowLevelRebalanceShares
     */
    function maxLowLevelRebalanceShares() external view returns (int256) {
        return MODULES.lowLevelRebalanceModule().maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesState());
    }

    /**
     * @dev see ILTV.maxLowLevelRebalanceBorrow
     */
    function maxLowLevelRebalanceBorrow() external view returns (int256) {
        return MODULES.lowLevelRebalanceModule().maxLowLevelRebalanceBorrow(maxLowLevelRebalanceBorrowState());
    }

    /**
     * @dev see ILTV.maxLowLevelRebalanceCollateral
     */
    function maxLowLevelRebalanceCollateral() external view returns (int256) {
        return MODULES.lowLevelRebalanceModule().maxLowLevelRebalanceCollateral(maxLowLevelRebalanceCollateralState());
    }
}
