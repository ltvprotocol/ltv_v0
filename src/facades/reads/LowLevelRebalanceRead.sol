// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceStateReader} from "src/state_reader/low_level/PreviewLowLevelRebalanceStateReader.sol";
import {MaxLowLevelRebalanceSharesStateReader} from "src/state_reader/low_level/MaxLowLevelRebalanceSharesStateReader.sol";
import {MaxLowLevelRebalanceBorrowStateReader} from "src/state_reader/low_level/MaxLowLevelRebalanceBorrowStateReader.sol";
import {MaxLowLevelRebalanceCollateralStateReader} from "src/state_reader/low_level/MaxLowLevelRebalanceCollateralStateReader.sol";

abstract contract LowLevelRebalanceRead is
    PreviewLowLevelRebalanceStateReader,
    MaxLowLevelRebalanceSharesStateReader,
    MaxLowLevelRebalanceBorrowStateReader,
    MaxLowLevelRebalanceCollateralStateReader
{
    function previewLowLevelRebalanceShares(int256 deltaShares) public view returns (int256, int256) {
        return modules.lowLevelRebalanceModule().previewLowLevelRebalanceShares(
            deltaShares, previewLowLevelRebalanceState()
        );
    }

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalanceModule().previewLowLevelRebalanceBorrow(
            deltaBorrowAssets, previewLowLevelRebalanceState()
        );
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalanceModule().previewLowLevelRebalanceCollateral(
            deltaCollateralAssets, previewLowLevelRebalanceState()
        );
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256)
    {
        return modules.lowLevelRebalanceModule().previewLowLevelRebalanceBorrowHint(
            deltaBorrowAssets, isSharesPositiveHint, previewLowLevelRebalanceState()
        );
    }

    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256)
    {
        return modules.lowLevelRebalanceModule().previewLowLevelRebalanceCollateralHint(
            deltaCollateralAssets, isSharesPositiveHint, previewLowLevelRebalanceState()
        );
    }

    function maxLowLevelRebalanceShares() external view returns (int256) {
        return modules.lowLevelRebalanceModule().maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesState());
    }

    function maxLowLevelRebalanceBorrow() external view returns (int256) {
        return modules.lowLevelRebalanceModule().maxLowLevelRebalanceBorrow(maxLowLevelRebalanceBorrowState());
    }

    function maxLowLevelRebalanceCollateral() external view returns (int256) {
        return modules.lowLevelRebalanceModule().maxLowLevelRebalanceCollateral(maxLowLevelRebalanceCollateralState());
    }
}
