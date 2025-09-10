// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {PreviewWithdrawVaultStateToCollateralData} from
    "src/math/abstracts/state_to_data/preview/PreviewWithdrawVaultStateToCollateralData.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

/**
 * @title MaxWithdrawRedeemCollateralStateToData
 * @notice Contract contains functionality to precalculate max withdraw/redeem collateral vault state to
 * data needed for max withdraw/redeem collateral calculations.
 */
contract MaxWithdrawRedeemCollateralStateToData is PreviewWithdrawVaultStateToCollateralData {
    /**
     * @notice Precalculates max withdraw/redeem collateral vault state to data needed for max withdraw/redeem collateral calculations.
     */
    function maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(
        MaxWithdrawRedeemCollateralVaultState memory state
    ) internal pure returns (MaxWithdrawRedeemCollateralVaultData memory) {
        MaxWithdrawRedeemCollateralVaultData memory data;
        data.realCollateral = CommonMath.convertRealCollateral(
            state.previewWithdrawVaultState.maxGrowthFeeState.withdrawRealCollateralAssets,
            state.previewWithdrawVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            false
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.previewWithdrawVaultState.maxGrowthFeeState.withdrawRealBorrowAssets,
            state.previewWithdrawVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            false
        );
        data.previewCollateralVaultData = _previewWithdrawVaultStateToPreviewCollateralVaultData(
            data.realCollateral, data.realBorrow, state.previewWithdrawVaultState
        );
        data.maxSafeLtvDividend = state.maxSafeLtvDividend;
        data.maxSafeLtvDivider = state.maxSafeLtvDivider;
        data.ownerBalance = state.ownerBalance;
        return data;
    }
}
