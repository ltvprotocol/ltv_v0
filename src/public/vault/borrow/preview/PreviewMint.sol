// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/Vault.sol";
import "../../../../math/MintRedeem.sol";

abstract contract PreviewMint is Vault {
    using uMulDiv for uint256;

    function previewMint(uint256 shares, PreviewDepositVaultState memory state) public pure returns (uint256 assets) {
        (assets,) = _previewMint(shares, previewDepositStateToPreviewDepositData(state));
    }

    function _previewMint(uint256 shares, PreviewDepositBorrowVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        uint256 sharesInUnderlying = shares.mulDivUp(data.depositTotalAssets, data.supplyAfterFee).mulDivUp(
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
                deltaShares: int256(sharesInUnderlying),
                isBorrow: true
            })
        );

        if (assetsInUnderlying > 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, resolve in favor of HODLer, round up to receive more assets
        return (uint256(-assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.borrowPrice), deltaFuture);
    }
}
