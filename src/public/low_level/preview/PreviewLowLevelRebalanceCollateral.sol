// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/PreviewLowLevelRebalanceStateToData.sol";

abstract contract PreviewLowLevelRebalanceCollateral is PreviewLowLevelRebalanceStateToData {
    using uMulDiv for uint256;

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateral,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory state
    ) public pure returns (int256, int256) {
        (int256 deltaRealBorrow, int256 deltaShares,) =
            _previewLowLevelRebalanceCollateralHint(deltaCollateral, isSharesPositiveHint, state);
        return (deltaRealBorrow, deltaShares);
    }

    function _previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateral,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory state
    ) internal pure returns (int256, int256, int256) {
        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) =
        _previewLowLevelRebalanceCollateral(
            deltaCollateral, previewLowLevelRebalanceStateToData(state, isSharesPositiveHint)
        );
        if (deltaShares >= 0 != isSharesPositiveHint) {
            (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceCollateral(
                deltaCollateral, previewLowLevelRebalanceStateToData(state, !isSharesPositiveHint)
            );
        }

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    function _previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets, LowLevelRebalanceData memory data)
        internal
        pure
        returns (int256, int256, int256)
    {
        return LowLevelRebalanceMath.calculateLowLevelRebalanceCollateral(deltaCollateralAssets, data);
    }
}
