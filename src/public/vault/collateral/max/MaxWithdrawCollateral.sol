// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewWithdrawCollateral.sol";
import "../preview/PreviewRedeemCollateral.sol";

abstract contract MaxWithdrawCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using uMulDiv for uint256;

    function maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return
            _maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    function _maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round up to assume smaller border
        uint256 maxSafeRealCollateral =
            uint256(data.realBorrow).mulDivUp(data.maxSafeLTVDivider, data.maxSafeLTVDividend);

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
        uint256 vaultWithdrawInAssets = (uint256(data.realCollateral) - maxSafeRealCollateral).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice
        );

        if (data.ownerBalance <= 3) {
            return 0;
        }

        (uint256 ownerBalanceAssets,) = _previewRedeemCollateral(data.ownerBalance - 3, data.previewCollateralVaultData);
        (uint256 ownerBalanceWithDelta,) =
            _previewWithdrawCollateral(ownerBalanceAssets, data.previewCollateralVaultData);
        if (ownerBalanceWithDelta > data.ownerBalance) {
            uint256 delta = ownerBalanceWithDelta + 3 - data.ownerBalance;
            if (ownerBalanceAssets < 2 * delta) {
                return 0;
            }
            ownerBalanceAssets = ownerBalanceAssets - 2 * delta;
        }

        return ownerBalanceAssets < vaultWithdrawInAssets ? ownerBalanceAssets : vaultWithdrawInAssets;
    }
}
