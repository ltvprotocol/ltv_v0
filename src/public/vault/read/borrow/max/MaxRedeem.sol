// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemBorrowVaultData.sol";
import {PreviewWithdraw} from "src/public/vault/read/borrow/preview/PreviewWithdraw.sol";
import {PreviewRedeem} from "src/public/vault/read/borrow/preview/PreviewRedeem.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

abstract contract MaxRedeem is PreviewWithdraw, PreviewRedeem {
    using UMulDiv for uint256;

    function maxRedeem(MaxWithdrawRedeemBorrowVaultState memory state) public pure returns (uint256 max) {
        return _maxRedeem(maxWithdrawRedeemStateToData(state));
    }

    function _maxRedeem(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256 max) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow =
            uint256(data.realCollateral).mulDivDown(data.maxSafeLtvDividend, data.maxSafeLtvDivider);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }

        uint256 maxWithdrawInAssets = (maxSafeRealBorrow - uint256(data.realBorrow)).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewWithdrawBorrowVaultData.borrowPrice
        );

        if (maxWithdrawInAssets <= 3) {
            return 0;
        }

        (uint256 maxWithdrawInShares,) = _previewWithdraw(maxWithdrawInAssets - 3, data.previewWithdrawBorrowVaultData);

        (uint256 maxWithdrawInAssetsWithDelta,) =
            _previewRedeem(maxWithdrawInShares, data.previewWithdrawBorrowVaultData);

        if (maxWithdrawInAssetsWithDelta > maxWithdrawInAssets) {
            uint256 delta = maxWithdrawInAssetsWithDelta + 3 - maxWithdrawInAssets;
            if (maxWithdrawInShares < 2 * delta) {
                return 0;
            }
            maxWithdrawInShares = maxWithdrawInShares - 2 * delta;
        }

        // round down to assume smaller border
        return data.ownerBalance < maxWithdrawInShares ? data.ownerBalance : maxWithdrawInShares;
    }
}
