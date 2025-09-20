// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintRedeemData} from "src/structs/data/vault/common/MintRedeemData.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/abstracts/VaultCollateral.sol";
import {MintRedeem} from "src/math/libraries/MintRedeem.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewRedeemCollateral
 * @notice This contract contains preview redeem collateral function implementation.
 */
abstract contract PreviewRedeemCollateral is VaultCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.previewRedeemCollateral
     */
    function previewRedeemCollateral(uint256 shares, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 assets)
    {
        (assets,) = _previewRedeemCollateral(shares, previewWithdrawVaultStateToPreviewCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate preview redeem collateral
     */
    function _previewRedeemCollateral(uint256 shares, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral
        uint256 sharesInUnderlying = shares.mulDivDown(data.totalAssetsCollateral, data.supplyAfterFee).mulDivDown(
            data.collateralPrice, 10 ** data.collateralTokenDecimals
        );

        (uint256 assetsInUnderlying, DeltaFuture memory deltaFuture) =
            _previewRedeemCollateralInUnderlying(sharesInUnderlying, data);

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral

        return (assetsInUnderlying.mulDivDown(10 ** data.collateralTokenDecimals, data.collateralPrice), deltaFuture);
    }

    /**
     * @dev base function to calculate preview deposit in underlying assets
     */
    function _previewRedeemCollateralInUnderlying(uint256 sharesInUnderlying, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                // casting to int256 is safe because sharesInUnderlying are considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaShares: -1 * int256(sharesInUnderlying),
                isBorrow: false
            })
        );

        if (assetsInUnderlying >= 0) {
            return (0, deltaFuture);
        }
        // casting to uint256 is safe because assetsInUnderlying is checked to be negative
        // and therefore it is smaller than type(uint256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(-assetsInUnderlying), deltaFuture);
    }
}
