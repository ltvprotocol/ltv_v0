// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {DepositWithdrawData} from "src/structs/data/vault/DepositWithdrawData.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import {PreviewWithdrawBorrowVaultData} from "src/structs/data/vault/PreviewWithdrawBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {DepositWithdraw} from "src/math/DepositWithdraw.sol";
import {Vault} from "src/math/Vault.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title PreviewWithdraw
 * @notice This contract contains preview withdraw function implementation.
 */
abstract contract PreviewWithdraw is Vault {
    using uMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.previewWithdraw
     */
    function previewWithdraw(uint256 assets, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewWithdraw(assets, previewWithdrawStateToPreviewWithdrawData(state));
    }

    /**
     * @dev base function to calculate preview withdraw
     */
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                deltaRealCollateral: 0,
                // casting to int256 is safe because assetsInUnderlying is considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaRealBorrow: int256(assetsInUnderlying)
            })
        );

        if (sharesInUnderlying > 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        return (
            // casting to uint256 is safe because sharesInUnderlying is checked to be negative
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256(-sharesInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.borrowPrice).mulDivUp(
                data.supplyAfterFee, data.withdrawTotalAssets
            ),
            deltaFuture
        );
    }
}
