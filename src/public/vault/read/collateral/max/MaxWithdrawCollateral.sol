// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {PreviewWithdrawCollateral} from "src/public/vault/read/collateral/preview/PreviewWithdrawCollateral.sol";
import {PreviewRedeemCollateral} from "src/public/vault/read/collateral/preview/PreviewRedeemCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxWithdrawCollateral
 * @notice This contract contains max withdraw collateral function implementation.
 */
abstract contract MaxWithdrawCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.maxWithdrawCollateral
     */
    function maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return
            _maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate max withdraw collateral
     */
    function _maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round up to assume smaller border
        uint256 maxSafeRealCollateral =
            uint256(data.realBorrow).mulDivUp(data.maxSafeLtvDivider, data.maxSafeLtvDividend);

        if (maxSafeRealCollateral >= uint256(data.realCollateral)) {
            return 0;
        }

        /**
         * Withdraw / reward math primer (abridged from internal design doc)
         *
         * Definitions
         * ------------------------------------------------------------------------
         *  f(x)  –  previewWithdraw(x): returns shares for `x` assets
         *  g(x)  –  reward component in previewWithdraw:
         *            f(x) = x + g(x)
         *
         * Core assumption  (rewards grow strictly slower than assets)
         * ------------------------------------------------------------------------
         *  ∀ x > y:  (x − y) / 2  >  g(y) − g(x) − 3
         *  The “–3” term guards the corner case x = y + 1,
         *  where rounding can make g(x) ≤ g(x‑1) + 3.
         *
         * Max‑withdraw issue
         * ------------------------------------------------------------------------
         *  previewWithdraw(previewRedeem(x)) may exceed x, so we search
         *  an `a` such that previewWithdraw(a) ≤ x.
         *
         * Proof sketch
         * ------------------------------------------------------------------------
         *  Let u   = userBalance
         *      b   = previewRedeem(u − 3)
         *      k   = previewWithdraw(b) − (u − 3)   // 0 < k ≤ 3
         *
         *  Show that f(b − 2k) < u:
         *     f(b)         = b + g(b)               = u − 3 + k
         *     f(b − 2k)    = b − 2k + g(b − 2k)
         *     Assumption ⇒ g(b) − g(b − 2k) < k + 3
         *     ⇒ f(b − 2k) < u                       // safe upper bound
         *
         *  Therefore (b − 2k) is a valid “max withdraw” asset amount
         *  that never burns more shares than the user owns.
         */
        // round down to assume smaller border
        uint256 vaultWithdrawInUnderlying = uint256(data.realCollateral) - maxSafeRealCollateral;
        uint256 ownerBalanceInUnderlying = data.ownerBalance.mulDivDown(
            data.previewCollateralVaultData.totalAssetsCollateral, data.previewCollateralVaultData.supplyAfterFee
        ).mulDivDown(
            data.previewCollateralVaultData.collateralPrice,
            10 ** data.previewCollateralVaultData.collateralTokenDecimals
        );

        if (ownerBalanceInUnderlying <= 3) {
            return 0;
        }

        (uint256 ownerBalanceAssetsInUnderlying,) =
            _previewRedeemCollateralInUnderlying(ownerBalanceInUnderlying - 3, data.previewCollateralVaultData);

        (uint256 ownerBalanceWithDelta,) =
            _previewWithdrawCollateralInUnderlying(ownerBalanceAssetsInUnderlying, data.previewCollateralVaultData);

        if (ownerBalanceWithDelta > ownerBalanceInUnderlying) {
            uint256 delta = ownerBalanceWithDelta + 3 - ownerBalanceInUnderlying;
            if (ownerBalanceAssetsInUnderlying < 2 * delta) {
                return 0;
            }
            ownerBalanceAssetsInUnderlying = ownerBalanceAssetsInUnderlying - 2 * delta;
        }

        uint256 maxWithdrawInUnderlying = ownerBalanceAssetsInUnderlying < vaultWithdrawInUnderlying
            ? ownerBalanceAssetsInUnderlying
            : vaultWithdrawInUnderlying;
        return maxWithdrawInUnderlying.mulDivDown(
            10 ** data.previewCollateralVaultData.collateralTokenDecimals,
            data.previewCollateralVaultData.collateralPrice
        );
    }
}
