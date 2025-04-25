// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../../structs/data/vault/PreviewBorrowVaultData.sol';
import '../../../structs/data/vault/TotalAssetsData.sol';
import '../../../structs/state/vault/TotalAssetsState.sol';
import '../../../structs/state/vault/PreviewVaultState.sol';
import '../../../structs/state/vault/MaxDepositMintBorrowVaultState.sol';
import '../../../structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol';
import '../../../structs/data/vault/MaxDepositMintBorrowVaultData.sol';
import '../../../structs/data/vault/MaxWithdrawRedeemBorrowVaultData.sol';
import '../MaxGrowthFee.sol';
import '../../../math2/CommonMath.sol';
import '../../erc20/TotalSupply.sol';

abstract contract Vault is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewVaultStateToPreviewBorrowVaultData(
        PreviewVaultState memory state,
        bool isDeposit
    ) internal pure returns (PreviewBorrowVaultData memory) {
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

        return _previewVaultStateToPreviewBorrowVaultData(realBorrow, realCollateral, state, isDeposit);
    }

    function _previewVaultStateToPreviewBorrowVaultData(
        uint256 realBorrow,
        uint256 realCollateral,
        PreviewVaultState memory state,
        bool isDeposit
    ) internal pure returns (PreviewBorrowVaultData memory) {
        PreviewBorrowVaultData memory data;
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
        data.borrowPrice = state.maxGrowthFeeState.totalAssetsState.borrowPrice;

        uint256 auctionStep = CommonMath.calculateAuctionStep(state.startAuction, state.blockNumber);

        data.userFutureRewardBorrow = CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep);
        data.userFutureRewardCollateral = CommonMath.calculateUserFutureRewardCollateral(int256(futureRewardCollateral), auctionStep);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;
        data.totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: data.borrowPrice})
        );

        uint256 withdrawTotalAssets = !isDeposit
            ? data.totalAssets
            : _totalAssets(false, TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: data.borrowPrice}));

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

    function maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(
        MaxDepositMintBorrowVaultState memory state
    ) internal pure returns (MaxDepositMintBorrowVaultData memory) {
        MaxDepositMintBorrowVaultData memory data;

        data.realCollateral = CommonMath.convertRealCollateral(
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.collateralPrice,
            true
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.borrowPrice,
            true
        );

        data.previewBorrowVaultData = _previewVaultStateToPreviewBorrowVaultData(data.realBorrow, data.realCollateral, state.previewVaultState, true);
        data.minProfitLTV = state.minProfitLTV;
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        return data;
    }

    function maxWithdrawRedeemBorrowVaultStateToMaxWithdrawRedeemBorrowVaultData(
        MaxWithdrawRedeemBorrowVaultState memory state
    ) internal pure returns (MaxWithdrawRedeemBorrowVaultData memory) {
        MaxWithdrawRedeemBorrowVaultData memory data;

        data.realCollateral = CommonMath.convertRealCollateral(
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.collateralPrice,
            false
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
            state.previewVaultState.maxGrowthFeeState.totalAssetsState.borrowPrice,
            false
        );

        data.previewBorrowVaultData = _previewVaultStateToPreviewBorrowVaultData(
            data.realBorrow,
            data.realCollateral,
            state.previewVaultState,
            false
        );
        data.maxSafeLTV = state.maxSafeLTV;
        data.ownerBalance = state.ownerBalance;
        return data;
    }

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
