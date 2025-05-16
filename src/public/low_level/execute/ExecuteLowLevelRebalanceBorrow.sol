// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/low_level/preview/PreviewLowLevelRebalanceBorrow.sol';
import 'src/public/low_level/max/MaxLowLevelRebalanceBorrow.sol';
import 'src/state_transition/ApplyMaxGrowthFee.sol';
import 'src/math/PreviewLowLevelRebalanceStateToData.sol';
import 'src/state_transition/ExecuteLowLevelRebalance.sol';
import 'src/errors/ILowLevelRebalanceErrors.sol';

abstract contract ExecuteLowLevelRebalanceBorrow is ExecuteLowLevelRebalance, PreviewLowLevelRebalanceBorrow, MaxLowLevelRebalanceBorrow, ApplyMaxGrowthFee, ILowLevelRebalanceErrors {
    function executeLowLevelRebalanceBorrow(int256 deltaBorrow) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, true);
    }

    function executeLowLevelRebalanceBorrowHint(
        int256 deltaBorrow,
        bool isSharesPositive
    ) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, isSharesPositive);
    }

    function _executeLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositive) internal returns (int256, int256) {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();
        LowLevelRebalanceData memory data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, isSharesPositive);
        int256 max = maxLowLevelRebalanceBorrow(
            MaxLowLevelRebalanceBorrowStateData({
                realBorrowAssets: state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
                targetLTV: state.previewLowLevelRebalanceState.targetLTV,
                borrowPrice: state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState.borrowPrice,
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying
            })
        );

        require(deltaBorrow <= max, ExceedsLowLevelRebalanceMaxDeltaBorrow(deltaBorrow, max));

        int256 depositTotalAssets = isSharesPositive ? int256(data.totalAssets) : -1;
        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceBorrow(
            deltaBorrow,
            data
        );

        if (deltaShares >= 0 != isSharesPositive) {
            data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, !isSharesPositive);
            (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceBorrow(deltaBorrow, data);
            if (depositTotalAssets == -1) {
                depositTotalAssets = int256(data.totalAssets);
            }
        }

        if (depositTotalAssets == -1) {
            depositTotalAssets = int256(totalAssets(true, state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState));
        }

        applyMaxGrowthFee(data.supplyAfterFee, uint256(depositTotalAssets));

        executeLowLevelRebalance(deltaRealCollateralAssets, deltaBorrow, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaShares);
    }
}
