// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/low_level/preview/PreviewLowLevelRebalanceBorrow.sol";
import "src/public/low_level/max/MaxLowLevelRebalanceBorrow.sol";
import "src/state_transition/ApplyMaxGrowthFee.sol";
import "src/math/state_to_data/preview/PreviewLowLevelRebalanceStateToData.sol";
import "src/state_transition/ExecuteLowLevelRebalance.sol";
import "src/errors/ILowLevelRebalanceErrors.sol";
import "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";

abstract contract ExecuteLowLevelRebalanceBorrow is
    ExecuteLowLevelRebalanceStateReader,
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceBorrow,
    MaxLowLevelRebalanceBorrow,
    ApplyMaxGrowthFee,
    ILowLevelRebalanceErrors
{
    function executeLowLevelRebalanceBorrow(int256 deltaBorrow)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, true);
    }

    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositive)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, isSharesPositive);
    }

    function _executeLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositive)
        internal
        returns (int256, int256)
    {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();

        LowLevelRebalanceData memory data =
            previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, isSharesPositive);
        int256 max = maxLowLevelRebalanceBorrow(
            MaxLowLevelRebalanceBorrowStateData({
                // using withdraw real borrow assets since it overestimates assets, so max value will be smaller
                realBorrowAssets: state.previewLowLevelRebalanceState.maxGrowthFeeState.withdrawRealBorrowAssets,
                targetLTVDividend: state.previewLowLevelRebalanceState.targetLTVDividend,
                targetLTVDivider: state.previewLowLevelRebalanceState.targetLTVDivider,
                borrowPrice: state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying
            })
        );

        require(deltaBorrow <= max, ExceedsLowLevelRebalanceMaxDeltaBorrow(deltaBorrow, max));

        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) =
            _previewLowLevelRebalanceBorrow(deltaBorrow, data);

        if (deltaShares >= 0 != isSharesPositive) {
            data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, !isSharesPositive);
            (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares) =
                _previewLowLevelRebalanceBorrow(deltaBorrow, data);
        }

        applyMaxGrowthFee(data.supplyAfterFee, data.withdrawTotalAssets);

        executeLowLevelRebalance(deltaRealCollateralAssets, deltaBorrow, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaShares);
    }
}
