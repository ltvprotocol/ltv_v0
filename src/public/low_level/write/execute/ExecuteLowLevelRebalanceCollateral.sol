// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteLowLevelRebalanceState} from "src/structs/state/low_level/execute/ExecuteLowLevelRebalanceState.sol";
import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/max/MaxLowLevelRebalanceCollateralStateData.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {ILowLevelRebalanceErrors} from "src/errors/ILowLevelRebalanceErrors.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {ExecuteLowLevelRebalance} from "src/state_transition/ExecuteLowLevelRebalance.sol";
import {ExecuteLowLevelRebalanceStateReader} from "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";
import {PreviewLowLevelRebalanceCollateral} from
    "src/public/low_level/read/preview/PreviewLowLevelRebalanceCollateral.sol";
import {MaxLowLevelRebalanceCollateral} from "src/public/low_level/read/max/MaxLowLevelRebalanceCollateral.sol";

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
                targetLtvDividend: state.previewLowLevelRebalanceState.targetLtvDividend,
                targetLtvDivider: state.previewLowLevelRebalanceState.targetLtvDivider,
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
