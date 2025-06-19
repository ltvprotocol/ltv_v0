// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/low_level/preview/PreviewLowLevelRebalanceShares.sol";
import "src/public/low_level/max/MaxLowLevelRebalanceShares.sol";
import "src/state_transition/ApplyMaxGrowthFee.sol";
import "src/math/state_to_data/preview/PreviewLowLevelRebalanceStateToData.sol";
import "src/state_transition/ExecuteLowLevelRebalance.sol";
import "src/errors/ILowLevelRebalanceErrors.sol";
import "src/state_reader/low_level/ExecuteLowLevelRebalanceStateReader.sol";

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
