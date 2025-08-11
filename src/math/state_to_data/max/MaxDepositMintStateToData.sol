// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewDepositStateToPreviewDepositData.sol";
import "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import "src/structs/data/vault/MaxDepositMintBorrowVaultData.sol";

contract MaxDepositMintStateToData is PreviewDepositStateToPreviewDepositData {
    function maxDepositMintStateToData(MaxDepositMintBorrowVaultState memory state)
        internal
        pure
        returns (MaxDepositMintBorrowVaultData memory)
    {
        MaxDepositMintBorrowVaultData memory data;

        data.realCollateral = CommonMath.convertRealCollateral(
            state.previewDepositVaultState.depositRealCollateralAssets,
            state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            true
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.previewDepositVaultState.depositRealBorrowAssets,
            state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            true
        );

        data.previewDepositBorrowVaultData = _previewDepositStateToPreviewDepositData(
            data.realBorrow, data.realCollateral, state.previewDepositVaultState
        );

        data.minProfitLTVDividend = state.minProfitLTVDividend;
        data.minProfitLTVDivider = state.minProfitLTVDivider;
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        return data;
    }
}
