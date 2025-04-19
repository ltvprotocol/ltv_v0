// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../Vault.sol';

abstract contract MaxWithdraw is Vault {
    using uMulDiv for uint256;

    function maxWithdraw(WithdrawRedeemState memory state) public pure returns (uint256) {
        return _maxWithdraw(withdrawRedeemStateToData(state));
    }

    function _maxWithdraw(WithdrawRedeemData memory data) internal pure returns (uint256) {
        // round down to assume smaller border
        uint256 maxSafeRealBorrow = uint256(data.vaultData.collateral).mulDivDown(data.maxSafeLTV, Constants.LTV_DIVIDER);
        if (maxSafeRealBorrow <= uint256(data.vaultData.borrow)) {
            return 0;
        }
        uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(data.vaultData.borrow);
        // round down to assume smaller border
        uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.vaultData.borrowPrice);
        // round down to assume smaller border
        uint256 userBalanceInAssets = data.ownerBalance.mulDivDown(data.vaultData.totalAssets, data.vaultData.supplyAfterFee);

        return userBalanceInAssets < vaultMaxWithdraw ? userBalanceInAssets : vaultMaxWithdraw;
    }
} 