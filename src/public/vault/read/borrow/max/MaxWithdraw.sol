// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemBorrowVaultData.sol";
import {PreviewWithdraw} from "src/public/vault/read/borrow/preview/PreviewWithdraw.sol";
import {PreviewRedeem} from "src/public/vault/read/borrow/preview/PreviewRedeem.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxWithdraw
 * @notice This contract contains max withdraw function implementation.
 */
abstract contract MaxWithdraw is PreviewWithdraw, PreviewRedeem {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.maxWithdraw
     */
    function maxWithdraw(MaxWithdrawRedeemBorrowVaultState memory state) external view nonReentrantRead returns (uint256) {
        return _maxWithdraw(maxWithdrawRedeemStateToData(state));
    }

    /**
     * @dev base function to calculate max withdraw
     */
    function _maxWithdraw(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow =
            uint256(data.realCollateral).mulDivDown(data.maxSafeLtvDividend, data.maxSafeLtvDivider);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }
        uint256 maxVaultWithdrawInUnderlying = maxSafeRealBorrow - uint256(data.realBorrow);
        // round down to assume smaller border

        uint256 userBalanceInUnderlying = data.ownerBalance.mulDivDown(
            data.previewWithdrawBorrowVaultData.withdrawTotalAssets, data.previewWithdrawBorrowVaultData.supplyAfterFee
        ).mulDivDown(
            data.previewWithdrawBorrowVaultData.borrowPrice,
            10 ** data.previewWithdrawBorrowVaultData.borrowTokenDecimals
        );

        if (userBalanceInUnderlying <= 3) {
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

        (uint256 userBalanceAssetsInUnderlying,) =
            _previewRedeemInUnderlying(userBalanceInUnderlying - 3, data.previewWithdrawBorrowVaultData);
        (uint256 userBalanceWithDelta,) =
            _previewWithdrawInUnderlying(userBalanceAssetsInUnderlying, data.previewWithdrawBorrowVaultData);
        if (userBalanceWithDelta > userBalanceInUnderlying) {
            uint256 delta = userBalanceWithDelta + 3 - userBalanceInUnderlying;
            if (userBalanceAssetsInUnderlying < 2 * delta) {
                return 0;
            }
            userBalanceAssetsInUnderlying = userBalanceAssetsInUnderlying - 2 * delta;
        }

        uint256 maxWithdrawInUnderlying = userBalanceAssetsInUnderlying < maxVaultWithdrawInUnderlying
            ? userBalanceAssetsInUnderlying
            : maxVaultWithdrawInUnderlying;

        return maxWithdrawInUnderlying.mulDivDown(
            10 ** data.previewWithdrawBorrowVaultData.borrowTokenDecimals,
            data.previewWithdrawBorrowVaultData.borrowPrice
        );
    }
}
