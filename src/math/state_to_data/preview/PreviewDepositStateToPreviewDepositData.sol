// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/vault/PreviewDepositVaultState.sol";
import "src/structs/data/vault/PreviewDepositBorrowVaultData.sol";
import "../../CommonMath.sol";
import "../../MaxGrowthFee.sol";
import "src/utils/MulDiv.sol";

contract PreviewDepositStateToPreviewDepositData is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewDepositStateToPreviewDepositData(PreviewDepositVaultState memory state)
        internal
        pure
        returns (PreviewDepositBorrowVaultData memory)
    {
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.depositRealBorrowAssets, state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice, true
        );
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.depositRealCollateralAssets, state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice, true
        );
        return _previewDepositStateToPreviewDepositData(realBorrow, realCollateral, state);
    }

    function _previewDepositStateToPreviewDepositData(
        uint256 realBorrow,
        uint256 realCollateral,
        PreviewDepositVaultState memory state
    ) internal pure returns (PreviewDepositBorrowVaultData memory) {
        PreviewDepositBorrowVaultData memory data;
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
        data.borrowPrice = state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice;

        uint24 auctionStep =
            CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber, state.auctionDuration);

        data.userFutureRewardBorrow =
            CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep, state.auctionDuration);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(
            int256(futureRewardCollateral), auctionStep, state.auctionDuration
        );
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.depositTotalAssets = _totalAssets(
            true, TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: data.borrowPrice})
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
