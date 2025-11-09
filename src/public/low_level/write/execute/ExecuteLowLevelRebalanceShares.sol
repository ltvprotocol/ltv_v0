// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LowLevelRebalanceData} from "../../../../structs/data/low_level/LowLevelRebalanceData.sol";
import {ExecuteLowLevelRebalanceState} from "../../../../structs/state/low_level/execute/ExecuteLowLevelRebalanceState.sol";
import {TotalAssetsState} from "../../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {MaxLowLevelRebalanceSharesData} from "../../../../structs/data/low_level/MaxLowLevelRebalanceSharesData.sol";
import {ILowLevelRebalanceErrors} from "../../../../errors/ILowLevelRebalanceErrors.sol";
import {ApplyMaxGrowthFee} from "../../../../state_transition/ApplyMaxGrowthFee.sol";
import {ExecuteLowLevelRebalance} from "../../../../state_transition/ExecuteLowLevelRebalance.sol";
import {ExecuteLowLevelRebalanceStateReader} from "../../../../state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";
import {PreviewLowLevelRebalanceShares} from "../../read/preview/PreviewLowLevelRebalanceShares.sol";
import {MaxLowLevelRebalanceShares} from "../../read/max/MaxLowLevelRebalanceShares.sol";
import {CommonMath} from "../../../../math/libraries/CommonMath.sol";

/**
 * @title ExecuteLowLevelRebalanceShares
 * @notice This contract contains execute low level rebalance shares function implementation.
 */
abstract contract ExecuteLowLevelRebalanceShares is
    ExecuteLowLevelRebalanceStateReader,
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceShares,
    MaxLowLevelRebalanceShares,
    ApplyMaxGrowthFee,
    ILowLevelRebalanceErrors
{
    /**
     * @dev see ILTV.executeLowLevelRebalanceShares
     * According to deltaShares it's either deposit or withdraw event. Depending
     * from this different rounding is used
     */
    function executeLowLevelRebalanceShares(int256 deltaShares)
        external
        isFunctionAllowed
        nonReentrant
        returns (int256, int256)
    {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();
        LowLevelRebalanceData memory data =
            previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, deltaShares >= 0);

        int256 max;
        if (deltaShares >= 0) {
            max = _maxLowLevelRebalanceShares(
                MaxLowLevelRebalanceSharesData({
                    depositRealCollateral: uint256(data.realCollateral),
                    depositRealBorrow: uint256(data.realBorrow),
                    maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying,
                    supplyAfterFee: data.supplyAfterFee,
                    borrowPrice: data.borrowPrice,
                    depositTotalAssets: data.totalAssets,
                    borrowTokenDecimals: data.borrowTokenDecimals
                })
            );
        } else {
            uint256 depositRealBorrow = CommonMath.convertRealBorrow(
                state.previewLowLevelRebalanceState.depositRealBorrowAssets,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
                true
            );
            uint256 depositRealCollateral = CommonMath.convertRealCollateral(
                state.previewLowLevelRebalanceState.depositRealCollateralAssets,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals,
                true
            );

            uint256 depositTotalAssets = _totalAssets(
                true,
                TotalAssetsState({
                    realCollateralAssets: state.previewLowLevelRebalanceState.depositRealCollateralAssets,
                    realBorrowAssets: state.previewLowLevelRebalanceState.depositRealBorrowAssets,
                    commonTotalAssetsState: state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState
                })
            );

            max = _maxLowLevelRebalanceShares(
                MaxLowLevelRebalanceSharesData({
                    depositRealCollateral: depositRealCollateral,
                    depositRealBorrow: depositRealBorrow,
                    maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying,
                    supplyAfterFee: data.supplyAfterFee,
                    borrowPrice: data.borrowPrice,
                    depositTotalAssets: depositTotalAssets,
                    borrowTokenDecimals: data.borrowTokenDecimals
                })
            );
        }

        require(deltaShares <= max, ExceedsLowLevelRebalanceMaxDeltaShares(deltaShares, max));

        (int256 deltaCollateral, int256 deltaBorrow, int256 deltaProtocolFutureReward) =
            _previewLowLevelRebalanceShares(deltaShares, data);

        applyMaxGrowthFee(data.supplyAfterFee, data.withdrawTotalAssets);

        executeLowLevelRebalance(deltaCollateral, deltaBorrow, deltaShares, deltaProtocolFutureReward);

        return (deltaCollateral, deltaBorrow);
    }
}
