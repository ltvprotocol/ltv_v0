// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/LTVState.sol';

abstract contract LowLevelRebalanceRead is LTVState {
    function previewLowLevelRebalanceShares(int256 deltaShares) public view returns (int256, int256) {
        return modules.lowLevelRebalancerRead().previewLowLevelRebalanceShares(deltaShares, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalancerRead().previewLowLevelRebalanceBorrow(deltaBorrowAssets, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        return modules.lowLevelRebalancerRead().previewLowLevelRebalanceCollateral(deltaCollateralAssets, previewLowLevelRebalanceState());
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) external view returns (int256, int256) {
        return
            modules.lowLevelRebalancerRead().previewLowLevelRebalanceBorrowHint(
                deltaBorrowAssets,
                isSharesPositiveHint,
                previewLowLevelRebalanceState()
            );
    }

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint
    ) external view returns (int256, int256) {
        return
            modules.lowLevelRebalancerRead().previewLowLevelRebalanceCollateralHint(
                deltaCollateralAssets,
                isSharesPositiveHint,
                previewLowLevelRebalanceState()
            );
    }

    function maxLowLevelRebalanceShares() external view returns (int256) {
        return modules.lowLevelRebalancerRead().maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesState());
    }

    function maxLowLevelRebalanceBorrow() external view returns (int256) {
        return modules.lowLevelRebalancerRead().maxLowLevelRebalanceBorrow(maxLowLevelRebalanceBorrowState());
    }

    function maxLowLevelRebalanceCollateral() external view returns (int256) {
        return modules.lowLevelRebalancerRead().maxLowLevelRebalanceCollateral(maxLowLevelRebalanceCollateralState());
    }
}
