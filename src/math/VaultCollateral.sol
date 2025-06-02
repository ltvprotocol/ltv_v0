// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/MaxGrowthFee.sol";
import "src/math/CommonMath.sol";
import "src/public/erc20/TotalSupply.sol";
import "src/public/vault/collateral/TotalAssetsCollateral.sol";
import "src/structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import "src/structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import "src/structs/state/vault/PreviewVaultState.sol";
import "src/structs/data/vault/PreviewCollateralVaultData.sol";
import "src/structs/data/vault/PreviewCollateralVaultData.sol";
import "src/structs/data/vault/MaxDepositMintCollateralVaultData.sol";
import "src/structs/data/vault/MaxWithdrawRedeemCollateralVaultData.sol";
import "src/structs/data/vault/ConvertCollateralData.sol";

abstract contract VaultCollateral is MaxGrowthFee, TotalAssetsCollateral {
    using uMulDiv for uint256;

    function previewVaultStateToPreviewCollateralVaultData(PreviewVaultState memory state, bool isDeposit)
        internal
        pure
        returns (PreviewCollateralVaultData memory)
    {
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
        return _previewVaultStateToPreviewCollateralVaultData(realCollateral, realBorrow, state, isDeposit);
    }

    function _previewVaultStateToPreviewCollateralVaultData(
        uint256 realCollateral,
        uint256 realBorrow,
        PreviewVaultState memory state,
        bool isDeposit
    ) internal pure returns (PreviewCollateralVaultData memory) {
        PreviewCollateralVaultData memory data;

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

        data.userFutureRewardBorrow =
            CommonMath.calculateUserFutureRewardBorrow(int256(futureRewardBorrow), auctionStep);
        data.userFutureRewardCollateral =
            CommonMath.calculateUserFutureRewardCollateral(int256(futureRewardCollateral), auctionStep);
        data.protocolFutureRewardBorrow = futureRewardBorrow - data.userFutureRewardBorrow;
        data.protocolFutureRewardCollateral = futureRewardCollateral - data.userFutureRewardCollateral;

        uint256 assets = _totalAssets(
            isDeposit,
            TotalAssetsData({
                collateral: data.collateral,
                borrow: data.borrow,
                borrowPrice: state.maxGrowthFeeState.totalAssetsState.borrowPrice
            })
        );
        data.totalAssetsCollateral = _totalAssetsCollateral(
            isDeposit,
            TotalAssetsCollateralData({
                totalAssets: assets,
                collateralPrice: state.maxGrowthFeeState.totalAssetsState.collateralPrice,
                borrowPrice: state.maxGrowthFeeState.totalAssetsState.borrowPrice
            })
        );

        uint256 withdrawTotalAssets = !isDeposit ? assets : totalAssets(false, state.maxGrowthFeeState.totalAssetsState);

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

    function maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(
        MaxDepositMintCollateralVaultState memory state
    ) internal pure returns (MaxDepositMintCollateralVaultData memory) {
        MaxDepositMintCollateralVaultData memory data;
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
        data.previewCollateralVaultData = _previewVaultStateToPreviewCollateralVaultData(
            data.realCollateral, data.realBorrow, state.previewVaultState, true
        );
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        data.minProfitLTV = state.minProfitLTV;
        return data;
    }

    function maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(
        MaxWithdrawRedeemCollateralVaultState memory state
    ) internal pure returns (MaxWithdrawRedeemCollateralVaultData memory) {
        MaxWithdrawRedeemCollateralVaultData memory data;
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
        data.previewCollateralVaultData = _previewVaultStateToPreviewCollateralVaultData(
            data.realCollateral, data.realBorrow, state.previewVaultState, false
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
        uint256 totalAssetsCollateral,
        uint256 collateralPrice
    ) internal pure returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying).mulDivDown(
            Constants.ORACLE_DIVIDER, collateralPrice
        ).mulDivDown(supplyAfterFee, totalAssetsCollateral);

        return availableSpaceInShares;
    }

    function maxGrowthFeeStateToConvertCollateralData(MaxGrowthFeeState memory state)
        internal
        pure
        returns (ConvertCollateralData memory)
    {
        ConvertCollateralData memory data;
        uint256 totalAssets = totalAssets(false, state.totalAssetsState);
        data.totalAssetsCollateral = _totalAssetsCollateral(
            false,
            TotalAssetsCollateralData({
                totalAssets: totalAssets,
                collateralPrice: state.totalAssetsState.collateralPrice,
                borrowPrice: state.totalAssetsState.borrowPrice
            })
        );

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: totalAssets,
                maxGrowthFee: state.maxGrowthFee,
                supply: totalSupply(state.supply),
                lastSeenTokenPrice: state.lastSeenTokenPrice
            })
        );

        return data;
    }
}
