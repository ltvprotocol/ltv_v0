// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {DepositWithdrawData} from "src/structs/data/vault/common/DepositWithdrawData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/abstracts/VaultCollateral.sol";
import {DepositWithdraw} from "src/math/libraries/DepositWithdraw.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewWithdrawCollateral
 * @notice This contract contains preview withdraw collateral function implementation.
 */
abstract contract PreviewWithdrawCollateral is VaultCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.previewWithdrawCollateral
     */
    function previewWithdrawCollateral(uint256 assets, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewWithdrawCollateral(assets, previewWithdrawVaultStateToPreviewCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate preview withdraw collateral
     */
    function _previewWithdrawCollateral(uint256 assets, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, assume user withdraws more to burn more shares
        uint256 assetsInUnderlying = assets.mulDivUp(data.collateralPrice, 10 ** data.collateralTokenDecimals);

        (uint256 sharesInUnderlying, DeltaFuture memory deltaFuture) =
            _previewWithdrawCollateralInUnderlying(assetsInUnderlying, data);

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        return (
            sharesInUnderlying.mulDivUp(10 ** data.collateralTokenDecimals, data.collateralPrice).mulDivUp(
                data.supplyAfterFee, data.totalAssetsCollateral
            ),
            deltaFuture
        );
    }

    function _previewWithdrawCollateralInUnderlying(uint256 assetsInUnderlying, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
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

        // casting to uint256 is safe because sharesInUnderlying is checked to be negative
        // and therefore it is smaller than type(uint256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(-sharesInUnderlying), deltaFuture);
    }
}
