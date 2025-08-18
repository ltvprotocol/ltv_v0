// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewWithdrawStateToPreviewWithdrawData.sol";
import "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import "src/structs/data/vault/MaxWithdrawRedeemBorrowVaultData.sol";

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
        data.maxSafeLTVDividend = state.maxSafeLTVDividend;
        data.maxSafeLTVDivider = state.maxSafeLTVDivider;
        data.ownerBalance = state.ownerBalance;
        return data;
    }
}
