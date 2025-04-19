// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../Structs2.sol';
import './MaxGrowthFee.sol';
import '../../math2/CommonMath.sol';
import '../erc20/TotalSupply.sol';

abstract contract Vault is MaxGrowthFee, TotalSupply {
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

        data.totalAssets = _totalAssets(
            state.isDeposit,
            TotalAssetsData({collateral: data.collateral, borrow: data.borrow, borrowPrice: data.borrowPrice})
        );

        uint256 withdrawTotalAssets = state.isDeposit
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
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;

        return data;
    }

    function depositMintStateToData(DepositMintState memory state) internal pure returns (DepositMintData memory) {
        DepositMintData memory data;
        data.vaultData = vaultStateToData(state.vaultState);
        data.minProfitLTV = state.minProfitLTV;
        return data;
    }

    function withdrawRedeemStateToData(WithdrawRedeemState memory state) internal pure returns (WithdrawRedeemData memory) {
        WithdrawRedeemData memory data;
        data.vaultData = vaultStateToData(state.vaultState);
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
