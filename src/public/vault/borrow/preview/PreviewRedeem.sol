// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/Vault.sol";
import "../../../../math/MintRedeem.sol";

abstract contract PreviewRedeem is Vault {
    using uMulDiv for uint256;

    function previewRedeem(uint256 shares, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 assets)
    {
        (assets,) = _previewRedeem(shares, previewWithdrawStateToPreviewWithdrawData(state));
    }

    function _previewRedeem(uint256 shares, PreviewWithdrawBorrowVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less assets for provided shares
        uint256 sharesInUnderlying = shares.mulDivDown(data.withdrawTotalAssets, data.supplyAfterFee).mulDivDown(
            data.borrowPrice, Constants.ORACLE_DIVIDER
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
                isBorrow: true
            })
        );

        if (assetsInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, give less assets
        return (uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.borrowPrice), deltaFuture);
    }
}
