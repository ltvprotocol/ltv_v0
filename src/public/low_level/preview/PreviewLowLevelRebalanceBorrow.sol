// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;
import 'src/math/PreviewLowLevelRebalanceStateToData.sol';

contract PreviewLowLevelRebalanceBorrow is PreviewLowLevelRebalanceStateToData {
    using uMulDiv for uint256;

    function previewLowLevelRebalanceBorrow(
        int256 deltaBorrow,
        PreviewLowLevelRebalanceState memory state
    ) public pure returns (int256, int256) {
        return previewLowLevelRebalanceBorrowHint(deltaBorrow, true, state);
    }

    function previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrow,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory state
    ) public pure returns (int256, int256) {
        (int256 deltaRealCollateral, int256 deltaShares, ) = _previewLowLevelRebalanceBorrowHint(deltaBorrow, isSharesPositiveHint, state);
        return (deltaRealCollateral, deltaShares);
    }

    function _previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrow,
        bool isSharesPositiveHint,
        PreviewLowLevelRebalanceState memory state
    ) internal pure returns (int256, int256, int256) {
        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceBorrow(
            deltaBorrow,
            previewLowLevelRebalanceStateToData(state, isSharesPositiveHint)
        );
        if (deltaShares >= 0 != isSharesPositiveHint) {
            (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceBorrow(
                deltaBorrow,
                previewLowLevelRebalanceStateToData(state, !isSharesPositiveHint)
            );
        }

        return (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    function _previewLowLevelRebalanceBorrow(
        int256 deltaBorrowAssets,
        LowLevelRebalanceData memory data
    ) internal pure returns (int256, int256, int256) {
        return LowLevelRebalanceMath.calculateLowLevelRebalanceBorrow(deltaBorrowAssets, data);
    }
}
