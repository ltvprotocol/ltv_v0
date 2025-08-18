// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/VaultCollateral.sol";
import "../../../../math/DepositWithdraw.sol";

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
                targetLTVDividend: data.targetLTVDividend,
                targetLTVDivider: data.targetLTVDivider,
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
