// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {DepositWithdrawData} from "src/structs/data/vault/common/DepositWithdrawData.sol";
import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewDepositBorrowVaultData} from "src/structs/data/vault/preview/PreviewDepositBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {DepositWithdraw} from "src/math/libraries/DepositWithdraw.sol";
import {Vault} from "src/math/abstracts/Vault.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

abstract contract PreviewDeposit is Vault {
    using UMulDiv for uint256;

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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                deltaRealCollateral: 0,
                // casting to int256 is safe because assetsInUnderlying is considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaRealBorrow: -1 * int256(assetsInUnderlying)
            })
        );

        if (sharesInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, resolve in favor of HODLer, round down to mint less shares
        return (
            // casting to uint256 is safe because sharesInUnderlying is checked to be non negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.borrowPrice).mulDivDown(
                data.supplyAfterFee, data.depositTotalAssets
            ),
            deltaFuture
        );
    }
}
