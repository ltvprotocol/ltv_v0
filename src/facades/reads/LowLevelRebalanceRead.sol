// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/readers/ModulesAddressStateReader.sol';
import '../../states/readers/ApplicationStateReader.sol';

abstract contract LowLevelRebalanceRead is ApplicationStateReader, ModulesAddressStateReader {
    function previewLowLevelRebalanceShares(int256 deltaShares) external view returns (int256, int256) {
        return getModules().lowLevelRebalancerRead().previewLowLevelRebalanceShares(deltaShares, getStateRepresentation());
    }

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        return getModules().lowLevelRebalancerRead().previewLowLevelRebalanceBorrow(deltaBorrowAssets, getStateRepresentation());
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        return getModules().lowLevelRebalancerRead().previewLowLevelRebalanceCollateral(deltaCollateralAssets, getStateRepresentation());
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) external view returns (int256, int256, int256) {
        return
            getModules().lowLevelRebalancerRead().previewLowLevelRebalanceBorrowHint(
                deltaBorrowAssets,
                isSharesPositiveHint,
                getStateRepresentation()
            );
    }

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint
    ) external view returns (int256, int256, int256) {
        return
            getModules().lowLevelRebalancerRead().previewLowLevelRebalanceCollateralHint(
                deltaCollateralAssets,
                isSharesPositiveHint,
                getStateRepresentation()
            );
    }

    function maxLowLevelRebalanceShares() external view returns (int256) {
        return getModules().lowLevelRebalancerRead().maxLowLevelRebalanceShares(getStateRepresentation());
    }

    function maxLowLevelRebalanceBorrow() external view returns (int256) {
        return getModules().lowLevelRebalancerRead().maxLowLevelRebalanceBorrow(getStateRepresentation());
    }

    function maxLowLevelRebalanceCollateral() external view returns (int256) {
        return getModules().lowLevelRebalancerRead().maxLowLevelRebalanceCollateral(getStateRepresentation());
    }
}
