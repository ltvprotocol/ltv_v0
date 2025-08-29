// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/PreviewCollateralVaultData.sol";
import {DepositWithdrawData} from "src/structs/data/vault/DepositWithdrawData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/VaultCollateral.sol";
import {DepositWithdraw} from "src/math/DepositWithdraw.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract PreviewWithdrawCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function previewWithdrawCollateral(uint256 assets, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewWithdrawCollateral(assets, previewWithdrawVaultStateToPreviewCollateralVaultData(state));
    }

    function _previewWithdrawCollateral(uint256 assets, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, assume user withdraws more to burn more shares
        uint256 assetsInUnderlying = assets.mulDivUp(data.collateralPrice, Constants.ORACLE_DIVIDER);

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
                // casting to int256 is safe because assetsInUnderlying are considered to be greater than type(int256).min
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaRealCollateral: -int256(assetsInUnderlying),
                deltaRealBorrow: 0
            })
        );

        if (sharesInUnderlying > 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        return (
            // casting to uint256 is safe because sharesInUnderlying is checked to be negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256(-sharesInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.collateralPrice).mulDivUp(
                data.supplyAfterFee, data.totalAssetsCollateral
            ),
            deltaFuture
        );
    }
}
