// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/VaultCollateral.sol";
import "../../../../math/MintRedeem.sol";

abstract contract PreviewMintCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function previewMintCollateral(uint256 shares, PreviewDepositVaultState memory state)
        public
        pure
        returns (uint256 assets)
    {
        (assets,) = _previewMintCollateral(shares, previewDepositVaultStateToPreviewCollateralVaultData(state));
    }

    function _previewMintCollateral(uint256 shares, PreviewCollateralVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> depositor conflict, round in favor of HODLer, round up to receive more assets
        uint256 sharesInUnderlying = shares.mulDivUp(data.totalAssetsCollateral, data.supplyAfterFee).mulDivUp(
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
                deltaShares: int256(sharesInUnderlying),
                isBorrow: false
            })
        );

        if (assetsInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, round in favor of HODLer, round up to get more collateral
        return (uint256(assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.collateralPrice), deltaFuture);
    }
}
