// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "../../../../../structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "../../../../../structs/data/vault/max/MaxWithdrawRedeemBorrowVaultData.sol";
import {PreviewWithdraw} from "../preview/PreviewWithdraw.sol";
import {PreviewRedeem} from "../preview/PreviewRedeem.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title MaxRedeem
 * @notice This contract contains max redeem function implementation.
 */
abstract contract MaxRedeem is PreviewWithdraw, PreviewRedeem {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.maxRedeem
     */
    function maxRedeem(MaxWithdrawRedeemBorrowVaultState memory state)
        external
        view
        nonReentrantRead
        returns (uint256 max)
    {
        return _maxRedeem(maxWithdrawRedeemStateToData(state));
    }

    /**
     * @dev base function to calculate max redeem
     */
    function _maxRedeem(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256 max) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow =
            uint256(data.realCollateral).mulDivDown(data.maxSafeLtvDividend, data.maxSafeLtvDivider);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }

        uint256 maxVaultWithdrawInUnderlying = maxSafeRealBorrow - uint256(data.realBorrow);

        if (maxVaultWithdrawInUnderlying <= 3) {
            return 0;
        }

        (uint256 maxWithdrawSharesInUnderlying,) =
            _previewWithdrawInUnderlying(maxVaultWithdrawInUnderlying - 3, data.previewWithdrawBorrowVaultData);

        (uint256 maxWithdrawInAssetsWithDelta,) =
            _previewRedeemInUnderlying(maxWithdrawSharesInUnderlying, data.previewWithdrawBorrowVaultData);

        if (maxWithdrawInAssetsWithDelta > maxVaultWithdrawInUnderlying) {
            uint256 delta = maxWithdrawInAssetsWithDelta + 3 - maxVaultWithdrawInUnderlying;
            if (maxWithdrawSharesInUnderlying < 2 * delta) {
                return 0;
            }
            maxWithdrawSharesInUnderlying = maxWithdrawSharesInUnderlying - 2 * delta;
        }

        uint256 maxVaultWithdrawInShares = maxWithdrawSharesInUnderlying.mulDivDown(
            10 ** data.previewWithdrawBorrowVaultData.borrowTokenDecimals,
            data.previewWithdrawBorrowVaultData.borrowPrice
        ).mulDivDown(
            data.previewWithdrawBorrowVaultData.supplyAfterFee, data.previewWithdrawBorrowVaultData.withdrawTotalAssets
        );

        // round down to assume smaller border
        return data.ownerBalance < maxVaultWithdrawInShares ? data.ownerBalance : maxVaultWithdrawInShares;
    }
}
