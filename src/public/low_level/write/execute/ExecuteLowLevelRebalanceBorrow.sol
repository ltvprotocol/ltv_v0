// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteLowLevelRebalanceState} from "src/structs/state/low_level/execute/ExecuteLowLevelRebalanceState.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {MaxLowLevelRebalanceBorrowStateData} from
    "src/structs/state/low_level/max/MaxLowLevelRebalanceBorrowStateData.sol";
import {ILowLevelRebalanceErrors} from "src/errors/ILowLevelRebalanceErrors.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {ExecuteLowLevelRebalance} from "src/state_transition/ExecuteLowLevelRebalance.sol";
import {ExecuteLowLevelRebalanceStateReader} from "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";
import {PreviewLowLevelRebalanceBorrow} from "src/public/low_level/read/preview/PreviewLowLevelRebalanceBorrow.sol";
import {MaxLowLevelRebalanceBorrow} from "src/public/low_level/read/max/MaxLowLevelRebalanceBorrow.sol";

/**
 * @title ExecuteLowLevelRebalanceBorrow
 * @notice This contract contains execute low level rebalance borrow function implementation.
 */
abstract contract ExecuteLowLevelRebalanceBorrow is
    ExecuteLowLevelRebalanceStateReader,
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceBorrow,
    MaxLowLevelRebalanceBorrow,
    ApplyMaxGrowthFee,
    ILowLevelRebalanceErrors
{
    /**
     * @dev see ILTV.executeLowLevelRebalanceBorrow
     */
    function executeLowLevelRebalanceBorrow(int256 deltaBorrow)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, true);
    }

    /**
     * @dev see ILTV.executeLowLevelRebalanceBorrowHint
     */
    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositive)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrow, isSharesPositive);
    }

    /**
     * @dev base function to calculate execute low level rebalance borrow with hint.
     * Hint is used to understand if user expects to receive or burn shares. Depending
     * on that different rounding will be used. If hint is incorrect, recalculation will be performed.
     */
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
                targetLtvDividend: state.previewLowLevelRebalanceState.targetLtvDividend,
                targetLtvDivider: state.previewLowLevelRebalanceState.targetLtvDivider,
                borrowPrice: state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying,
                borrowTokenDecimals: state
                    .previewLowLevelRebalanceState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .borrowTokenDecimals
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
