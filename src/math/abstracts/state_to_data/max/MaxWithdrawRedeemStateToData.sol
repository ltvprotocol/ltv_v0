// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemBorrowVaultData.sol";
import {PreviewWithdrawStateToPreviewWithdrawData} from
    "src/math/abstracts/state_to_data/preview/PreviewWithdrawStateToPreviewWithdrawData.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

/**
 * @title MaxWithdrawRedeemStateToData
 * @notice Contract contains functionality to precalculate max withdraw/redeem vault state to
 * data needed for max withdraw/redeem calculations.
 */
contract MaxWithdrawRedeemStateToData is PreviewWithdrawStateToPreviewWithdrawData {
    /**
     * @notice Precalculates max withdraw/redeem vault state to data needed for max withdraw/redeem calculations.
     */
    function maxWithdrawRedeemStateToData(MaxWithdrawRedeemBorrowVaultState memory state)
        internal
        pure
        returns (MaxWithdrawRedeemBorrowVaultData memory)
    {
        MaxWithdrawRedeemBorrowVaultData memory data;

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

        data.previewWithdrawBorrowVaultData = _previewWithdrawStateToPreviewWithdrawData(
            data.realBorrow, data.realCollateral, state.previewWithdrawVaultState
        );
        data.maxSafeLtvDividend = state.maxSafeLtvDividend;
        data.maxSafeLtvDivider = state.maxSafeLtvDivider;
        data.ownerBalance = state.ownerBalance;
        return data;
    }
}
