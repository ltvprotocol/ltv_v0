// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/Vault.sol";
import "../../../../math/DepositWithdraw.sol";

abstract contract PreviewDeposit is Vault {
    using uMulDiv for uint256;

    function previewDeposit(uint256 assets, PreviewDepositVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewDeposit(assets, previewDepositStateToPreviewDepositData(state));
    }

    function _previewDeposit(uint256 assets, PreviewDepositBorrowVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // depositor/withdrawer <=> HODLer conflict, assume user deposits less to mint less shares
        uint256 assetsInUnderlying = assets.mulDivDown(data.borrowPrice, Constants.ORACLE_DIVIDER);

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
                deltaRealBorrow: -1 * int256(assetsInUnderlying)
            })
        );

        if (sharesInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, resolve in favor of HODLer, round down to mint less shares
        return (
            uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.borrowPrice).mulDivDown(
                data.supplyAfterFee, data.depositTotalAssets
            ),
            deltaFuture
        );
    }
}
