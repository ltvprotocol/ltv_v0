// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintRedeemData} from "../../../../../structs/data/vault/common/MintRedeemData.sol";
import {PreviewDepositVaultState} from "../../../../../structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewCollateralVaultData} from "../../../../../structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {DeltaFuture} from "../../../../../structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "../../../../../math/abstracts/VaultCollateral.sol";
import {MintRedeem} from "../../../../../math/libraries/MintRedeem.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title PreviewMintCollateral
 * @notice This contract contains preview mint collateral function implementation.
 */
abstract contract PreviewMintCollateral is VaultCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.previewMintCollateral
     */
    function previewMintCollateral(uint256 shares, PreviewDepositVaultState memory state)
        external
        view
        nonReentrantRead
        returns (uint256 assets)
    {
        (assets,) = _previewMintCollateral(shares, previewDepositVaultStateToPreviewCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate preview mint collateral
     */
    function _previewMintCollateral(uint256 shares, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> depositor conflict, round in favor of HODLer, round up to receive more assets
        uint256 sharesInUnderlying = shares.mulDivUp(data.totalAssetsCollateral, data.supplyAfterFee).mulDivUp(
            data.collateralPrice, 10 ** data.collateralTokenDecimals
        );

        (uint256 assetsInUnderlying, DeltaFuture memory deltaFuture) =
            _previewMintCollateralInUnderlying(sharesInUnderlying, data);

        // HODLer <=> depositor conflict, round in favor of HODLer, round up to get more collateral
        return (assetsInUnderlying.mulDivUp(10 ** data.collateralTokenDecimals, data.collateralPrice), deltaFuture);
    }

    /**
     * @dev base function to calculate preview deposit in underlying assets
     */
    function _previewMintCollateralInUnderlying(uint256 sharesInUnderlying, PreviewCollateralVaultData memory data)
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
                // casting to int256 is safe because sharesInUnderlying is considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaShares: int256(sharesInUnderlying),
                isBorrow: false
            })
        );

        if (assetsInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // casting to uint256 is safe because assetsInUnderlying is checked to be positive
        // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(assetsInUnderlying), deltaFuture);
    }
}
