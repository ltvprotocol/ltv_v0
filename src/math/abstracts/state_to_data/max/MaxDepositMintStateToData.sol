// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/MaxDepositMintBorrowVaultData.sol";
import {PreviewDepositStateToPreviewDepositData} from
    "src/math/abstracts/state_to_data/preview/PreviewDepositStateToPreviewDepositData.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

/**
 * @title MaxDepositMintStateToData
 * @notice Contract contains functionality to precalculate max deposit/mint vault state to
 * data needed for max deposit/mint calculations.
 */
contract MaxDepositMintStateToData is PreviewDepositStateToPreviewDepositData {
    /**
     * @notice Precalculates max deposit/mint vault state to data needed for max deposit/mint calculations.
     */
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

        data.minProfitLtvDividend = state.minProfitLtvDividend;
        data.minProfitLtvDivider = state.minProfitLtvDivider;
        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        return data;
    }
}
