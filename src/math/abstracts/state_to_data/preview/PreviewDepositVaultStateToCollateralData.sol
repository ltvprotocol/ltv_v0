// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsCollateralData} from "src/structs/data/vault/total_assets/TotalAssetsCollateralData.sol";
import {TotalAssetsCollateral} from "src/public/vault/read/collateral/TotalAssetsCollateral.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewDepositVaultStateToCollateralData
 * @notice Contract contains functionality to precalculate pure preview deposit vault state to
 * data needed for preview collateral vault data calculations.
 */
abstract contract PreviewDepositVaultStateToCollateralData is TotalAssetsCollateral, MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @notice Precalculates pure preview deposit vault state to data needed for preview collateral vault data calculations.
     */
    function previewDepositVaultStateToPreviewCollateralVaultData(PreviewDepositVaultState memory state)
        internal
        pure
        returns (PreviewCollateralVaultData memory)
    {
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.depositRealCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals,
            true
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.depositRealBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
            true
        );
        return _previewDepositVaultStateToPreviewCollateralVaultData(realCollateral, realBorrow, state);
    }

    /**
     * @notice Precalculates pure preview deposit vault state to data needed for preview collateral vault data calculations.
     * @dev realCollateral and realBorrow are made arguments since it can be needed to cache them in another place
     */
    function _previewDepositVaultStateToPreviewCollateralVaultData(
        uint256 realCollateral,
        uint256 realBorrow,
        PreviewDepositVaultState memory state
    ) internal pure returns (PreviewCollateralVaultData memory) {
        PreviewCollateralVaultData memory data;

        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals,
            true
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
            true
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals,
            true
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
            true
        );

        // casting to int256 is safe because realCollateral is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
        // casting to int256 is safe because realBorrow is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.borrow = int256(realBorrow) + data.futureBorrow + futureRewardBorrow;
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

        uint256 assets = _totalAssets(
            true,
            TotalAssetsData({
                collateral: data.collateral,
                borrow: data.borrow,
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                borrowTokenDecimals: state.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals
            })
        );
        data.totalAssetsCollateral = _totalAssetsCollateral(
            true,
            TotalAssetsCollateralData({
                totalAssets: assets,
                collateralPrice: state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                borrowTokenDecimals: state.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
                collateralTokenDecimals: state.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals
            })
        );

        data.withdrawTotalAssets = totalAssets(
            false,
            TotalAssetsState({
                realCollateralAssets: state.maxGrowthFeeState.withdrawRealCollateralAssets,
                realBorrowAssets: state.maxGrowthFeeState.withdrawRealBorrowAssets,
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
        data.collateralSlippage = state.collateralSlippage;
        data.borrowSlippage = state.borrowSlippage;
        data.collateralTokenDecimals = state.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals;

        return data;
    }
}
