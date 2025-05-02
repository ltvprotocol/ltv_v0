// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/low_level/preview/PreviewLowLevelRebalanceCollateral.sol';
import 'src/public/low_level/max/MaxLowLevelRebalanceCollateral.sol';
import 'src/state_transition/ApplyMaxGrowthFee.sol';
import 'src/math2/PreviewLowLevelRebalanceStateToData.sol';
import 'src/state_transition/ExecuteLowLevelRebalance.sol';

contract ExecuteLowLevelRebalanceCollateral is
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceCollateral,
    MaxLowLevelRebalanceCollateral,
    ApplyMaxGrowthFee
{
    error ExceedsLowLevelRebalanceMaxDeltaCollateral(int256 deltaCollateral, int256 max);

    function executeLowLevelRebalanceCollateral(int256 deltaCollateral) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateral, true);
    }

    function executeLowLevelRebalanceCollateralHint(
        int256 deltaCollateral,
        bool isSharesPositive
    ) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateral, isSharesPositive);
    }

    function _executeLowLevelRebalanceCollateralHint(int256 deltaCollateral, bool isSharesPositive) internal returns (int256, int256) {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();
        LowLevelRebalanceData memory data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, isSharesPositive);
        int256 max = maxLowLevelRebalanceCollateral(
            MaxLowLevelRebalanceCollateralStateData({
                realCollateralAssets: state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
                targetLTV: state.previewLowLevelRebalanceState.targetLTV,
                collateralPrice: state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState.collateralPrice,
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying
            })
        );

        require(deltaCollateral <= max, ExceedsLowLevelRebalanceMaxDeltaCollateral(deltaCollateral, max));

        int256 depositTotalAssets = isSharesPositive ? int256(data.totalAssets) : -1;
        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceCollateral(
            deltaCollateral,
            data
        );

        if (deltaShares >= 0 != isSharesPositive) {
            data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, !isSharesPositive);
            (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceCollateral(deltaCollateral, data);
            if (depositTotalAssets == -1) {
                depositTotalAssets = int256(data.totalAssets);
            }
        }

        if (depositTotalAssets == -1) {
            depositTotalAssets = int256(totalAssets(true, state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState));
        }

        applyMaxGrowthFee(data.supplyAfterFee, uint256(depositTotalAssets));

        executeLowLevelRebalance(deltaCollateral, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealBorrowAssets, deltaShares);
    }
}
