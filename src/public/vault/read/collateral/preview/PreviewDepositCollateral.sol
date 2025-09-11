// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {DepositWithdrawData} from "src/structs/data/vault/common/DepositWithdrawData.sol";
import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {PreviewCollateralVaultData} from "src/structs/data/vault/preview/PreviewCollateralVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {VaultCollateral} from "src/math/abstracts/VaultCollateral.sol";
import {DepositWithdraw} from "src/math/libraries/DepositWithdraw.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewDepositCollateral
 * @notice This contract contains preview deposit collateral function implementation.
 */
abstract contract PreviewDepositCollateral is VaultCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.previewDepositCollateral
     */
    function previewDepositCollateral(uint256 assets, PreviewDepositVaultState memory state)
        public
        pure
        returns (uint256 shares)
    {
        (shares,) = _previewDepositCollateral(assets, previewDepositVaultStateToPreviewCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate preview deposit collateral
     */
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                // casting to int256 is safe because realCollateralInUnderlying is considered to be smaller than type(int256).max
                // forge-lint: disable-next-line(unsafe-typecast)
                deltaRealCollateral: int256(realCollateralInUnderlying),
                deltaRealBorrow: 0
            })
        );

        if (sharesInUnderlying < 0) {
            return (0, deltaFuture);
        }

        // HODLer <=> depositor conflict, round in favor of HODLer, round down to mint less shares
        return (
            // casting to uint256 is safe because sharesInUnderlying is checked to be non negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.collateralPrice).mulDivDown(
                data.supplyAfterFee, data.totalAssetsCollateral
            ),
            deltaFuture
        );
    }
}
