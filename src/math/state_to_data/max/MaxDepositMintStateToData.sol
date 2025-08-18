// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/MaxDepositMintBorrowVaultData.sol";
import {PreviewDepositStateToPreviewDepositData} from "src/math/state_to_data/preview/PreviewDepositStateToPreviewDepositData.sol";
import {CommonMath} from "src/math/CommonMath.sol";

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
