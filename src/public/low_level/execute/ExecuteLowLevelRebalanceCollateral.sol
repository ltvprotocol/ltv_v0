// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/low_level/preview/PreviewLowLevelRebalanceCollateral.sol";
import "src/public/low_level/max/MaxLowLevelRebalanceCollateral.sol";
import "src/state_transition/ApplyMaxGrowthFee.sol";
import "src/math/state_to_data/preview/PreviewLowLevelRebalanceStateToData.sol";
import "src/state_transition/ExecuteLowLevelRebalance.sol";
import "src/errors/ILowLevelRebalanceErrors.sol";
import "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";

abstract contract ExecuteLowLevelRebalanceCollateral is
    ExecuteLowLevelRebalanceStateReader,
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceCollateral,
    MaxLowLevelRebalanceCollateral,
    ApplyMaxGrowthFee,
    ILowLevelRebalanceErrors
{
    function executeLowLevelRebalanceCollateral(int256 deltaCollateral)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateral, true);
    }

    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateral, bool isSharesPositive)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateral, isSharesPositive);
    }

    function _executeLowLevelRebalanceCollateralHint(int256 deltaCollateral, bool isSharesPositive)
        internal
        returns (int256, int256)
    {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();
        LowLevelRebalanceData memory data =
            previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, isSharesPositive);
        int256 max = maxLowLevelRebalanceCollateral(
            // using deposit real collateral assets since it overestimate collateral assets, so max value will be smaller
            MaxLowLevelRebalanceCollateralStateData({
                realCollateralAssets: state.previewLowLevelRebalanceState.depositRealCollateralAssets,
                targetLTVDividend: state.previewLowLevelRebalanceState.targetLTVDividend,
                targetLTVDivider: state.previewLowLevelRebalanceState.targetLTVDivider,
                collateralPrice: state
                    .previewLowLevelRebalanceState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .collateralPrice,
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying
            })
        );

        require(deltaCollateral <= max, ExceedsLowLevelRebalanceMaxDeltaCollateral(deltaCollateral, max));

        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) =
            _previewLowLevelRebalanceCollateral(deltaCollateral, data);

        if (deltaShares >= 0 != isSharesPositive) {
            data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, !isSharesPositive);
            (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares) =
                _previewLowLevelRebalanceCollateral(deltaCollateral, data);
        }

        applyMaxGrowthFee(data.supplyAfterFee, data.withdrawTotalAssets);

        executeLowLevelRebalance(deltaCollateral, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealBorrowAssets, deltaShares);
    }
}
