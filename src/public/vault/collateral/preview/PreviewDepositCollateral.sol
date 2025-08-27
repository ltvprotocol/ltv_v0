// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {DepositWithdrawData} from "src/structs/data/vault/DepositWithdrawData.sol";
import {PreviewDepositVaultState} from "src/structs/state/vault/PreviewDepositVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/PreviewCollateralVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/VaultCollateral.sol";
import {DepositWithdraw} from "src/math/DepositWithdraw.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract PreviewDepositCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function previewDepositCollateral(uint256 assets, PreviewDepositVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewDepositCollateral(assets, previewDepositVaultStateToPreviewCollateralVaultData(state));
    }

    function _previewDepositCollateral(uint256 assets, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // depositor <=> HODLer conflict, assume user deposits less to mint less shares
        uint256 realCollateralInUnderlying = assets.mulDivDown(data.collateralPrice, Constants.ORACLE_DIVIDER);
        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = DepositWithdraw.calculateDepositWithdraw(
            DepositWithdrawData({
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                deltaRealCollateral: int256(realCollateralInUnderlying),
                deltaRealBorrow: 0
            })
        );

        if (sharesInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, round in favor of HODLer, round down to mint less shares
        return (
            uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.collateralPrice).mulDivDown(
                data.supplyAfterFee, data.totalAssetsCollateral
            ),
            deltaFuture
        );
    }
}
