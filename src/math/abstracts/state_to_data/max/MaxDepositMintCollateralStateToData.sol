// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultState} from "../../../../structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "../../../../structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {PreviewDepositVaultStateToCollateralData} from
    "../preview/PreviewDepositVaultStateToCollateralData.sol";
import {CommonMath} from "../../../libraries/CommonMath.sol";

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
            state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralTokenDecimals,
            true
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.previewDepositVaultState.depositRealBorrowAssets,
            state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowTokenDecimals,
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
