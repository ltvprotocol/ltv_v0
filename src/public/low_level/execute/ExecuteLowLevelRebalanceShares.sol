// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {ExecuteLowLevelRebalanceState} from "src/structs/state/low_level/ExecuteLowLevelRebalanceState.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {MaxLowLevelRebalanceSharesData} from "src/structs/data/low_level/MaxLowLevelRebalanceSharesData.sol";
import {ILowLevelRebalanceErrors} from "src/errors/ILowLevelRebalanceErrors.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {ExecuteLowLevelRebalance} from "src/state_transition/ExecuteLowLevelRebalance.sol";
import {ExecuteLowLevelRebalanceStateReader} from "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";
import {PreviewLowLevelRebalanceShares} from "src/public/low_level/preview/PreviewLowLevelRebalanceShares.sol";
import {MaxLowLevelRebalanceShares} from "src/public/low_level/max/MaxLowLevelRebalanceShares.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

abstract contract ExecuteLowLevelRebalanceShares is
    ExecuteLowLevelRebalanceStateReader,
    ExecuteLowLevelRebalance,
    PreviewLowLevelRebalanceShares,
    MaxLowLevelRebalanceShares,
    ApplyMaxGrowthFee,
    ILowLevelRebalanceErrors
{
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
                    depositTotalAssets: data.totalAssets
                })
            );
        } else {
            uint256 depositRealBorrow = CommonMath.convertRealBorrow(
                state.previewLowLevelRebalanceState.depositRealBorrowAssets,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                true
            );
            uint256 depositRealCollateral = CommonMath.convertRealCollateral(
                state.previewLowLevelRebalanceState.depositRealCollateralAssets,
                state.previewLowLevelRebalanceState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                true
            );

            uint256 depositTotalAssets = totalAssets(
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
                    depositTotalAssets: depositTotalAssets
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
