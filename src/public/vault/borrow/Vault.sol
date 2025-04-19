// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../../Structs2.sol';
import './MaxGrowthFee.sol';
import '../../../math2/CommonMath.sol';

abstract contract Vault is MaxGrowthFee {
    using uMulDiv for uint256;

    function vaultStateToData(VaultState memory state) internal pure returns (VaultData memory) {
        VaultData memory data;
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            state.isDeposit
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            state.isDeposit
        );
        data.futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.totalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            state.isDeposit
        );
        data.futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.totalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            state.isDeposit
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.totalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            state.isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.totalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            state.isDeposit
        );

        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + data.futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.maxGrowthFeeState.totalAssetsState.borrowPrice;

        uint256 auctionStep = CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber);

        data.userFutureRewardBorrow = CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(int256(futureRewardCollateral), auctionStep);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        data.totalAssets = _totalAssets(state.isDeposit, TotalAssetsData({
            collateral: data.collateral,
            borrow: data.borrow,
            borrowPrice: data.borrowPrice
        }));

        data.supplyAfterFee = _previewSupplyAfterFee(MaxGrowthFeeData({
            totalAssets: data.totalAssets,
            maxGrowthFee: state.maxGrowthFeeState.maxGrowthFee,
            supply: state.maxGrowthFeeState.supply,
            lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
        }));

        data.targetLTV = state.targetLTV;
        data.collateralSlippage = state.collateralSlippage;
        data.borrowSlippage = state.borrowSlippage;
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;

        return data;
    }
}
