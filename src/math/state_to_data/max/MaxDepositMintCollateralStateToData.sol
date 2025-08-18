// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/MaxDepositMintCollateralVaultData.sol";
import {PreviewDepositVaultStateToCollateralData} from "src/math/state_to_data/preview/PreviewDepositVaultStateToCollateralData.sol";
import {CommonMath} from "src/math/CommonMath.sol";

contract MaxDepositMintCollateralStateToData is PreviewDepositVaultStateToCollateralData {
    function maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(
        MaxDepositMintCollateralVaultState memory state
    ) internal pure returns (MaxDepositMintCollateralVaultData memory) {
        MaxDepositMintCollateralVaultData memory data;
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
        data.previewCollateralVaultData = _previewDepositVaultStateToPreviewCollateralVaultData(
            data.realCollateral, data.realBorrow, state.previewDepositVaultState
        );
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        data.minProfitLTVDividend = state.minProfitLTVDividend;
        data.minProfitLTVDivider = state.minProfitLTVDivider;
        return data;
    }
}
