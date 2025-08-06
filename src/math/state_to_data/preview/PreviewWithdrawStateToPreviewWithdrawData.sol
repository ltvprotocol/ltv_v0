// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import "src/structs/data/vault/PreviewWithdrawBorrowVaultData.sol";
import "../../CommonMath.sol";
import "../../MaxGrowthFee.sol";
import "src/utils/MulDiv.sol";

contract PreviewWithdrawStateToPreviewWithdrawData is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewWithdrawStateToPreviewWithdrawData(PreviewWithdrawVaultState memory state)
        internal
        pure
        returns (PreviewWithdrawBorrowVaultData memory)
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

        return _previewWithdrawStateToPreviewWithdrawData(realBorrow, realCollateral, state);
    }

    function _previewWithdrawStateToPreviewWithdrawData(
        uint256 realBorrow,
        uint256 realCollateral,
        PreviewWithdrawVaultState memory state
    ) internal pure returns (PreviewWithdrawBorrowVaultData memory) {
        PreviewWithdrawBorrowVaultData memory data;
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

        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + data.futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice;

        uint256 auctionStep =
            CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber, state.auctionDuration);

        data.userFutureRewardBorrow =
            CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep, state.auctionDuration);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(
            int256(futureRewardCollateral), auctionStep, state.auctionDuration
        );
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.withdrawTotalAssets = _totalAssets(
            false, TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: data.borrowPrice})
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
