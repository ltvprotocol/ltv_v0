// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/LTVState.sol';

abstract contract LowLevelRebalanceRead is LTVState {
    function previewLowLevelRebalanceShares(int256 deltaShares) public view returns (int256, int256) {
        return modules.lowLevelRebalance().previewLowLevelRebalanceShares(deltaShares, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalance().previewLowLevelRebalanceBorrow(deltaBorrowAssets, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalance().previewLowLevelRebalanceCollateral(deltaCollateralAssets, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) external view returns (int256, int256) {
        return modules.lowLevelRebalance().previewLowLevelRebalanceBorrowHint(deltaBorrowAssets, isSharesPositiveHint, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) external view returns (int256, int256) {
        return modules.lowLevelRebalance().previewLowLevelRebalanceCollateralHint(deltaCollateralAssets, isSharesPositiveHint, previewLowLevelRebalanceState());
    }

    function maxLowLevelRebalanceShares() external view returns (int256) {
        return modules.lowLevelRebalance().maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesState());
    }

    function maxLowLevelRebalanceBorrow() external view returns (int256) {
        return modules.lowLevelRebalance().maxLowLevelRebalanceBorrow(maxLowLevelRebalanceBorrowState());
    }

    function maxLowLevelRebalanceCollateral() external view returns (int256) {
        return modules.lowLevelRebalance().maxLowLevelRebalanceCollateral(maxLowLevelRebalanceCollateralState());
    }
}
