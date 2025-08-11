// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/vault/PreviewDepositVaultState.sol";
import "src/structs/data/vault/PreviewCollateralVaultData.sol";
import "src/public/vault/collateral/TotalAssetsCollateral.sol";
import "../../CommonMath.sol";
import "../../MaxGrowthFee.sol";

abstract contract PreviewDepositVaultStateToCollateralData is TotalAssetsCollateral, MaxGrowthFee {
    using uMulDiv for uint256;

    function previewDepositVaultStateToPreviewCollateralVaultData(PreviewDepositVaultState memory state)
        internal
        pure
        returns (PreviewCollateralVaultData memory)
    {
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.depositRealCollateralAssets, state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice, true
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.depositRealBorrowAssets, state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice, true
        );
        return _previewDepositVaultStateToPreviewCollateralVaultData(realCollateral, realBorrow, state);
    }

    function _previewDepositVaultStateToPreviewCollateralVaultData(
        uint256 realCollateral,
        uint256 realBorrow,
        PreviewDepositVaultState memory state
    ) internal pure returns (PreviewCollateralVaultData memory) {
        PreviewCollateralVaultData memory data;

        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            true
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            true
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            true
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            true
        );

        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
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
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice
            })
        );
        data.totalAssetsCollateral = _totalAssetsCollateral(
            true,
            TotalAssetsCollateralData({
                totalAssets: assets,
                collateralPrice: state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice
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

        data.targetLTVDividend = state.targetLTVDividend;
        data.targetLTVDivider = state.targetLTVDivider;
        data.collateralSlippage = state.collateralSlippage;
        data.borrowSlippage = state.borrowSlippage;

        return data;
    }
}
