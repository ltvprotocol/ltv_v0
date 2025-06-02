// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewWithdraw.sol";
import "../preview/PreviewRedeem.sol";

abstract contract MaxRedeem is PreviewWithdraw, PreviewRedeem {
    using uMulDiv for uint256;

    function maxRedeem(MaxWithdrawRedeemBorrowVaultState memory state) public pure returns (uint256 max) {
        return _maxRedeem(maxWithdrawRedeemBorrowVaultStateToMaxWithdrawRedeemBorrowVaultData(state));
    }

    function _maxRedeem(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256 max) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow = uint256(data.realCollateral).mulDivDown(data.maxSafeLTV, Constants.LTV_DIVIDER);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }

        uint256 maxWithdrawInAssets = (maxSafeRealBorrow - uint256(data.realBorrow)).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewBorrowVaultData.borrowPrice
        );

        (uint256 vaultMaxWithdrawShares,) = _previewWithdraw(maxWithdrawInAssets, data.previewBorrowVaultData);
        // round down to assume smaller border
        return data.ownerBalance < vaultMaxWithdrawShares ? data.ownerBalance : vaultMaxWithdrawShares;
    }
}
