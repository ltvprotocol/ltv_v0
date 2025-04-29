// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../preview/PreviewWithdraw.sol';
import '../preview/PreviewRedeem.sol';

abstract contract MaxWithdraw is PreviewWithdraw, PreviewRedeem {
    using uMulDiv for uint256;

    function maxWithdraw(MaxWithdrawRedeemBorrowVaultState memory state) public pure returns (uint256) {
        return _maxWithdraw(maxWithdrawRedeemBorrowVaultStateToMaxWithdrawRedeemBorrowVaultData(state));
    }

    function _maxWithdraw(MaxWithdrawRedeemBorrowVaultData memory data) internal pure returns (uint256) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow = uint256(data.realCollateral).mulDivDown(data.maxSafeLTV, Constants.LTV_DIVIDER);
        if (maxSafeRealBorrow <= uint256(data.realBorrow)) {
            return 0;
        }
        uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(data.realBorrow);
        // round down to assume smaller border
        uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.previewBorrowVaultData.borrowPrice);
        // round down to assume smaller border
        (uint256 userBalanceInAssets, ) = _previewRedeem(data.ownerBalance, data.previewBorrowVaultData);

        return userBalanceInAssets < vaultMaxWithdraw ? userBalanceInAssets : vaultMaxWithdraw;
    }
}
