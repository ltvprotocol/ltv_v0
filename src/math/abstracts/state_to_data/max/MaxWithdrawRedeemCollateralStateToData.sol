// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemCollateralVaultState} from "src/structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/MaxWithdrawRedeemCollateralVaultData.sol";
import {PreviewWithdrawVaultStateToCollateralData} from
    "src/math/abstracts/state_to_data/preview/PreviewWithdrawVaultStateToCollateralData.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";

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
        data.maxSafeLtvDividend = state.maxSafeLtvDividend;
        data.maxSafeLtvDivider = state.maxSafeLtvDivider;
        data.ownerBalance = state.ownerBalance;
        return data;
    }
}
