// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/Vault.sol";
import "../../../../math/DepositWithdraw.sol";

abstract contract PreviewWithdraw is Vault {
    using uMulDiv for uint256;

    function previewWithdraw(uint256 assets, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewWithdraw(assets, previewWithdrawStateToPreviewWithdrawData(state));
    }

    function _previewWithdraw(uint256 assets, PreviewWithdrawBorrowVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // depositor/withdrawer <=> HODLer conflict, assume user withdraws more to burn more shares
        uint256 assetsInUnderlying = assets.mulDivUp(data.borrowPrice, Constants.ORACLE_DIVIDER);
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
                targetLTVDividend: data.targetLTVDividend,
                targetLTVDivider: data.targetLTVDivider,
                deltaRealCollateral: 0,
                deltaRealBorrow: int256(assetsInUnderlying)
            })
        );

        if (sharesInUnderlying > 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        return (
            uint256(-sharesInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.borrowPrice).mulDivUp(
                data.supplyAfterFee, data.withdrawTotalAssets
            ),
            deltaFuture
        );
    }
}
