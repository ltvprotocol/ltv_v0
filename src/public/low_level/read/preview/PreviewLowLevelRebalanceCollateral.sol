// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/preview/PreviewLowLevelRebalanceState.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {PreviewLowLevelRebalanceStateToData} from
    "src/math/abstracts/state_to_data/preview/PreviewLowLevelRebalanceStateToData.sol";
import {LowLevelRebalanceMath} from "src/math/libraries/LowLevelRebalanceMath.sol";
import {UMulDiv} from "src/utils/MulDiv.sol";

abstract contract PreviewLowLevelRebalanceCollateral is PreviewLowLevelRebalanceStateToData {
    using UMulDiv for uint256;

    function previewLowLevelRebalanceCollateral(int256 deltaCollateral, PreviewLowLevelRebalanceState memory state)
        public
        pure
        returns (int256, int256)
    {
        return previewLowLevelRebalanceCollateralHint(deltaCollateral, true, state);
    }

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
