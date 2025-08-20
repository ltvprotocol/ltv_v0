// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "src/structs/data/vault/MaxWithdrawRedeemBorrowVaultData.sol";
import {PreviewWithdrawStateToPreviewWithdrawData} from
    "src/math/state_to_data/preview/PreviewWithdrawStateToPreviewWithdrawData.sol";
import {CommonMath} from "src/math/CommonMath.sol";

contract MaxWithdrawRedeemStateToData is PreviewWithdrawStateToPreviewWithdrawData {
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
