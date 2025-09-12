// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintRedeemData} from "src/structs/data/vault/common/MintRedeemData.sol";
import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {PreviewWithdrawBorrowVaultData} from "src/structs/data/vault/preview/PreviewWithdrawBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {MintRedeem} from "src/math/libraries/MintRedeem.sol";
import {Vault} from "src/math/abstracts/Vault.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewRedeem
 * @notice This contract contains preview redeem function implementation.
 */
abstract contract PreviewRedeem is Vault {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.previewRedeem
     */
    function previewRedeem(uint256 shares, PreviewWithdrawVaultState memory state)
        public
        pure
        returns (uint256 assets)
    {
        (assets,) = _previewRedeem(shares, previewWithdrawStateToPreviewWithdrawData(state));
    }

    /**
     * @dev base function to calculate preview redeem
     */
    function _previewRedeem(uint256 shares, PreviewWithdrawBorrowVaultData memory data)
        internal
        pure
        returns (uint256, DeltaFuture memory)
    {
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less assets for provided shares
        uint256 sharesInUnderlying = shares.mulDivDown(data.withdrawTotalAssets, data.supplyAfterFee).mulDivDown(
            data.borrowPrice, 10 ** data.borrowTokenDecimals
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                // casting to int256 is safe because sharesInUnderlying is considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaShares: -1 * int256(sharesInUnderlying),
                isBorrow: true
            })
        );

        if (assetsInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, give less assets
        // casting to uint256 is safe because assetsInUnderlying is checked to be non negative
        // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(assetsInUnderlying).mulDivDown(10 ** data.borrowTokenDecimals, data.borrowPrice), deltaFuture);
    }
}
