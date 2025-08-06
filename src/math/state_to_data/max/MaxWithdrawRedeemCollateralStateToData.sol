// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewWithdrawVaultStateToCollateralData.sol";
import "src/structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import "src/structs/data/vault/MaxWithdrawRedeemCollateralVaultData.sol";

contract MaxWithdrawRedeemCollateralStateToData is PreviewWithdrawVaultStateToCollateralData {
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
        data.maxSafeLTVDividend = state.maxSafeLTVDividend;
        data.maxSafeLTVDivider = state.maxSafeLTVDivider;
        data.ownerBalance = state.ownerBalance;
        return data;
    }
}
