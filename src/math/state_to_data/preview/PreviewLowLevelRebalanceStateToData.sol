// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/CommonMath.sol";
import "src/math/MaxGrowthFee.sol";
import "src/math/LowLevelRebalanceMath.sol";
import "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

abstract contract PreviewLowLevelRebalanceStateToData is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewLowLevelRebalanceStateToData(PreviewLowLevelRebalanceState memory state, bool isDeposit)
        public
        pure
        returns (LowLevelRebalanceData memory data)
    {
        // true since we calculate top border
        data.realCollateral = int256(
            CommonMath.convertRealCollateral(
                isDeposit ? state.depositRealCollateralAssets : state.maxGrowthFeeState.withdrawRealCollateralAssets,
                state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                isDeposit
            )
        );
        data.realBorrow = int256(
            CommonMath.convertRealBorrow(
                isDeposit ? state.depositRealBorrowAssets : state.maxGrowthFeeState.withdrawRealBorrowAssets,
                state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                isDeposit
            )
        );
        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            isDeposit
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            isDeposit
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            isDeposit
        );

        uint24 auctionStep =
            CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber, state.auctionDuration);

        data.userFutureRewardBorrow =
            CommonMath.calculateUserFutureRewardBorrow(futureRewardBorrow, auctionStep, state.auctionDuration);
        data.userFutureRewardCollateral =
            CommonMath.calculateUserFutureRewardCollateral(futureRewardCollateral, auctionStep, state.auctionDuration);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.collateralPrice = state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice;
        data.borrowPrice = state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice;

        data.totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({
                collateral: data.realCollateral + data.futureCollateral + futureRewardCollateral,
                borrow: data.realBorrow + data.futureBorrow + futureRewardBorrow,
                borrowPrice: data.borrowPrice
            })
        );

        // need to recalculate everything with another rounding
        data.withdrawTotalAssets = !isDeposit
            ? data.totalAssets
            : totalAssets(
                false,
                TotalAssetsState({
                    realBorrowAssets: state.maxGrowthFeeState.withdrawRealBorrowAssets,
                    realCollateralAssets: state.maxGrowthFeeState.withdrawRealCollateralAssets,
                    commonTotalAssetsState: state.maxGrowthFeeState.commonTotalAssetsState
                })
            );

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: data.withdrawTotalAssets,
                maxGrowthFeeDividend: state.maxGrowthFeeState.maxGrowthFeeDividend,
                maxGrowthFeeDivider: state.maxGrowthFeeState.maxGrowthFeeDivider,
                supply: totalSupply(state.maxGrowthFeeState.supply),
                lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
            })
        );

        data.targetLTVDividend = state.targetLTVDividend;
        data.targetLTVDivider = state.targetLTVDivider;
    }
}
