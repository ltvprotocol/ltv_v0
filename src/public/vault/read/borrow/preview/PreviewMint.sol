// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewDepositBorrowVaultData} from "src/structs/data/vault/preview/PreviewDepositBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {MintRedeemData} from "src/structs/data/vault/common/MintRedeemData.sol";
import {MintRedeem} from "src/math/libraries/MintRedeem.sol";
import {Vault} from "src/math/abstracts/Vault.sol";
import {UMulDiv} from "src/utils/MulDiv.sol";

abstract contract PreviewMint is Vault {
    using UMulDiv for uint256;

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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                // casting to int256 is safe because sharesInUnderlying are considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaShares: int256(sharesInUnderlying),
                isBorrow: true
            })
        );

        if (assetsInUnderlying > 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, resolve in favor of HODLer, round up to receive more assets
        // casting to uint256 is safe because assetsInUnderlying is checked to be negative
        // and therefore it is smaller than type(uint256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(-assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, data.borrowPrice), deltaFuture);
    }
}
