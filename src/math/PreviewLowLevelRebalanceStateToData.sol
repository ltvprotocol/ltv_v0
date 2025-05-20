// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/math/CommonMath.sol';
import 'src/math/MaxGrowthFee.sol';
import 'src/math/LowLevelRebalanceMath.sol';
import 'src/structs/state/low_level/PreviewLowLevelRebalanceState.sol';
abstract contract PreviewLowLevelRebalanceStateToData is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewLowLevelRebalanceStateToData(
        PreviewLowLevelRebalanceState memory state,
        bool isDeposit
    ) public pure returns (LowLevelRebalanceData memory data) {
        // true since we calculate top border
        data.realCollateral = int256(
            CommonMath.convertRealCollateral(
                state.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
                state.maxGrowthFeeState.totalAssetsState.collateralPrice,
                isDeposit
            )
        );
        data.realBorrow = int256(
            CommonMath.convertRealBorrow(
                state.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
                state.maxGrowthFeeState.totalAssetsState.borrowPrice,
                isDeposit
            )
        );
        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.totalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            isDeposit
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.totalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            isDeposit
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.totalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.totalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            isDeposit
        );

        uint256 auctionStep = CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber);

        data.userFutureRewardBorrow = CommonMath.calculateUserFutureRewardBorrow(futureRewardBorrow, auctionStep);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(futureRewardCollateral, auctionStep);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.collateralPrice = state.maxGrowthFeeState.totalAssetsState.collateralPrice;
        data.borrowPrice = state.maxGrowthFeeState.totalAssetsState.borrowPrice;

        data.totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({
                collateral: data.realCollateral + data.futureCollateral + futureRewardCollateral,
                borrow: data.realBorrow + data.futureBorrow + futureRewardBorrow,
                borrowPrice: data.borrowPrice
            })
        );

        // need to recalculate everything with another rounding
        uint256 withdrawTotalAssets = !isDeposit ? data.totalAssets : totalAssets(false, state.maxGrowthFeeState.totalAssetsState);

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: withdrawTotalAssets,
                maxGrowthFee: state.maxGrowthFeeState.maxGrowthFee,
                supply: totalSupply(state.maxGrowthFeeState.supply),
                lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
            })
        );

        data.targetLTV = state.targetLTV;
    }
}
