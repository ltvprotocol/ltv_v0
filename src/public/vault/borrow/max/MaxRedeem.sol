// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxWithdraw.sol';
import '../preview/PreviewWithdraw.sol';
import '../preview/PreviewRedeem.sol';

abstract contract MaxRedeem is MaxWithdraw, PreviewWithdraw {
    using uMulDiv for uint256;

    function maxRedeem(WithdrawRedeemState memory state) public pure returns (uint256 max) {
        return _maxRedeem(withdrawRedeemStateToData(state));
    }

    function _maxRedeem(WithdrawRedeemData memory data) internal pure returns (uint256 max) {
        uint256 maxWithdrawAmount = _maxWithdraw(data);
        (max, ) = _previewWithdraw(maxWithdrawAmount, data.vaultData);
    }
}
