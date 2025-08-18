// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MintRedeemData} from "src/structs/data/vault/MintRedeemData.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/PreviewCollateralVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/VaultCollateral.sol";
import {MintRedeem} from "src/math/MintRedeem.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract PreviewRedeemCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function previewRedeemCollateral(uint256 shares, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 assets)
    {
        (assets,) = _previewRedeemCollateral(shares, previewWithdrawVaultStateToPreviewCollateralVaultData(state));
    }

    function _previewRedeemCollateral(uint256 shares, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral
        uint256 sharesInUnderlying = shares.mulDivDown(data.totalAssetsCollateral, data.supplyAfterFee).mulDivDown(
            data.collateralPrice, Constants.ORACLE_DIVIDER
        );

        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            MintRedeemData({
                collateral: data.collateral,
                borrow: data.borrow,
                futureBorrow: data.futureBorrow,
                futureCollateral: data.futureCollateral,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                collateralSlippage: data.collateralSlippage,
                borrowSlippage: data.borrowSlippage,
                targetLTVDividend: data.targetLTVDividend,
                targetLTVDivider: data.targetLTVDivider,
                deltaShares: -1 * int256(sharesInUnderlying),
                isBorrow: false
            })
        );

        if (assetsInUnderlying >= 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral
        return (uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.collateralPrice), deltaFuture);
    }
}
