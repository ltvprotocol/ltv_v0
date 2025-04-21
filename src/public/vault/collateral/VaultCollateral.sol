// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../../Structs2.sol';
import '../MaxGrowthFee.sol';
import '../../../math2/CommonMath.sol';
import '../../erc20/TotalSupply.sol';
import './TotalAssetsCollateral.sol';

abstract contract VaultCollateral is MaxGrowthFee, TotalSupply, TotalAssetsCollateral {
    using uMulDiv for uint256;

    function previewCollateralVaultStateToPreviewCollateralVaultData(
        PreviewCollateralVaultState memory state,
        bool isDeposit
    ) internal pure returns (PreviewCollateralVaultData memory) {
        PreviewCollateralVaultData memory data;
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            isDeposit
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            isDeposit
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

        data.collateral = int256(realCollateral) + data.futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + data.futureBorrow + futureRewardBorrow;
        data.collateralPrice = state.maxGrowthFeeState.totalAssetsState.collateralPrice;

        uint256 auctionStep = CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber);

        data.userFutureRewardBorrow = CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(int256(futureRewardCollateral), auctionStep);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        uint256 totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: state.maxGrowthFeeState.totalAssetsState.borrowPrice})
        );
        data.totalAssetsCollateral = _totalAssetsCollateral(
            isDeposit,
            TotalAssetsCollateralData({
                totalAssets: totalAssets,
                collateralPrice: state.maxGrowthFeeState.totalAssetsState.collateralPrice,
                borrowPrice: state.maxGrowthFeeState.totalAssetsState.borrowPrice
            })
        );

        uint256 withdrawTotalAssets = !isDeposit
            ? totalAssets
            : _totalAssets(false, TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: state.maxGrowthFeeState.totalAssetsState.borrowPrice}));

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: withdrawTotalAssets,
                maxGrowthFee: state.maxGrowthFeeState.maxGrowthFee,
                supply: totalSupply(state.maxGrowthFeeState.supply),
                lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
            })
        );

        data.targetLTV = state.targetLTV;
        data.collateralSlippage = state.collateralSlippage;
        data.borrowSlippage = state.borrowSlippage;

        return data;
    }

    // function maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(
    //     MaxDepositMintBorrowVaultState memory state
    // ) internal pure returns (MaxDepositMintBorrowVaultData memory) {
    //     MaxDepositMintBorrowVaultData memory data;
    //     data.previewBorrowVaultData = previewBorrowVaultStateToPreviewBorrowVaultData(state.previewBorrowVaultState, true);
    //     data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
    //     data.minProfitLTV = state.minProfitLTV;
    //     return data;
    // }

    // function maxWithdrawRedeemBorrowVaultStateToMaxWithdrawRedeemBorrowVaultData(
    //     MaxWithdrawRedeemBorrowVaultState memory state
    // ) internal pure returns (MaxWithdrawRedeemBorrowVaultData memory) {
    //     MaxWithdrawRedeemBorrowVaultData memory data;
    //     data.previewBorrowVaultData = previewBorrowVaultStateToPreviewBorrowVaultData(state.previewBorrowVaultState, false);
    //     data.maxSafeLTV = state.maxSafeLTV;
    //     data.ownerBalance = state.ownerBalance;
    //     return data;
    // }

    function getAvailableSpaceInShares(
        int256 collateral,
        int256 borrow,
        uint256 maxTotalAssetsInUnderlying,
        uint256 supplyAfterFee,
        uint256 totalAssets,
        uint256 borrowPrice
    ) internal pure returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying)
            .mulDivDown(Constants.ORACLE_DIVIDER, borrowPrice)
            .mulDivDown(supplyAfterFee, totalAssets);

        return availableSpaceInShares;
    }
}
