// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {PreviewDepositVaultStateToCollateralData} from
    "src/math/abstracts/state_to_data/preview/PreviewDepositVaultStateToCollateralData.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

/**
 * @title MaxDepositMintCollateralStateToData
 * @notice Contract contains functionality to precalculate max deposit/mint collateral vault state to
 * data needed for max deposit mint collateral calculations.
 */
contract MaxDepositMintCollateralStateToData is PreviewDepositVaultStateToCollateralData {
    /**
     * @notice Precalculates max deposit/mint collateral vault state to data needed for max deposit/mint collateral calculations.
     */
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
        data.minProfitLtvDividend = state.minProfitLtvDividend;
        data.minProfitLtvDivider = state.minProfitLtvDivider;
        return data;
    }
}
