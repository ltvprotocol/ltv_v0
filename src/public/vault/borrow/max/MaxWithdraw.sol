// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewWithdraw.sol";
import "../preview/PreviewRedeem.sol";

abstract contract MaxWithdraw is PreviewWithdraw, PreviewRedeem {
    using uMulDiv for uint256;

    function maxWithdraw(MaxWithdrawRedeemBorrowVaultState memory state) public pure returns (uint256) {
        return _maxWithdraw(maxWithdrawRedeemStateToData(state));
    }

    function _maxWithdraw(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow =
            uint256(data.realCollateral).mulDivDown(data.maxSafeLTVDividend, data.maxSafeLTVDivider);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }
        uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(data.realBorrow);
        // round down to assume smaller border
        uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewWithdrawBorrowVaultData.borrowPrice
        );

        if (data.ownerBalance <= 3) {
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
        (uint256 userBalanceInAssets,) = _previewRedeem(data.ownerBalance - 3, data.previewWithdrawBorrowVaultData);
        (uint256 userBalanceWithDelta,) = _previewWithdraw(userBalanceInAssets, data.previewWithdrawBorrowVaultData);
        if (userBalanceWithDelta > data.ownerBalance) {
            uint256 delta = userBalanceWithDelta + 3 - data.ownerBalance;
            if (userBalanceInAssets < 2 * delta) {
                return 0;
            }
            userBalanceInAssets = userBalanceInAssets - 2 * delta;
        }

        return userBalanceInAssets < vaultMaxWithdraw ? userBalanceInAssets : vaultMaxWithdraw;
    }
}
