// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsCollateralData} from "src/structs/data/vault/total_assets/TotalAssetsCollateralData.sol";
import {TotalAssetsCollateral} from "src/public/vault/read/collateral/TotalAssetsCollateral.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title PreviewWithdrawVaultStateToCollateralData
 * @notice Contract contains functionality to precalculate preview withdraw vault state to
 * data needed for preview collateral vault data calculations.
 */
abstract contract PreviewWithdrawVaultStateToCollateralData is TotalAssetsCollateral, MaxGrowthFee {
    using uMulDiv for uint256;

    /**
     * @notice Precalculates preview withdraw vault state to data needed for preview collateral vault data calculations.
     */
    function previewWithdrawVaultStateToPreviewCollateralVaultData(PreviewWithdrawVaultState memory state)
        internal
        pure
        returns (PreviewCollateralVaultData memory)
    {
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.maxGrowthFeeState.withdrawRealCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            false
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.maxGrowthFeeState.withdrawRealBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            false
        );
        return _previewWithdrawVaultStateToPreviewCollateralVaultData(realCollateral, realBorrow, state);
    }

    /**
     * @notice Precalculates preview withdraw vault state to data needed for preview collateral vault data calculations.
     * @dev realCollateral and realBorrow are made arguments since it can be needed to cache them in another place
     */
    function _previewWithdrawVaultStateToPreviewCollateralVaultData(
        uint256 realCollateral,
        uint256 realBorrow,
        PreviewWithdrawVaultState memory state
    ) internal pure returns (PreviewCollateralVaultData memory) {
        PreviewCollateralVaultData memory data;

        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            false
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            false
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            false
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            false
        );

        // casting to int256 is safe because realCollateral and realBorrow are considered to be smaller than type(int256).max
        // forge-lint: disable-start(unsafe-typecast)
        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + data.futureBorrow + futureRewardBorrow;
        // forge-lint: disable-end(unsafe-typecast)
        data.collateralPrice = state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice;

        uint24 auctionStep =
            CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber, state.auctionDuration);

        data.userFutureRewardBorrow =
            CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep, state.auctionDuration);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(
            int256(futureRewardCollateral), auctionStep, state.auctionDuration
        );
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.withdrawTotalAssets = _totalAssets(
            false,
            TotalAssetsData({
                collateral: data.collateral,
                borrow: data.borrow,
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice
            })
        );
        data.totalAssetsCollateral = _totalAssetsCollateral(
            false,
            TotalAssetsCollateralData({
                totalAssets: data.withdrawTotalAssets,
                collateralPrice: state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice
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
        data.collateralSlippage = state.collateralSlippage;
        data.borrowSlippage = state.borrowSlippage;

        return data;
    }
}
