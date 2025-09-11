// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/preview/PreviewLowLevelRebalanceState.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewLowLevelRebalanceStateToData
 * @notice Contract contains functionality to precalculate pure preview low level rebalance state to
 * data needed for low level rebalance calculations.
 */
abstract contract PreviewLowLevelRebalanceStateToData is MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @notice Precalculates pure preview low level rebalance state to data needed for low level rebalance calculations.
     */
    function previewLowLevelRebalanceStateToData(PreviewLowLevelRebalanceState memory state, bool isDeposit)
        internal
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

        data.targetLtvDividend = state.targetLtvDividend;
        data.targetLtvDivider = state.targetLtvDivider;
    }
}
