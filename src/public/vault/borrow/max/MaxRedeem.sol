// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxWithdraw.sol';
import '../preview/PreviewWithdraw.sol';

abstract contract MaxRedeem is MaxWithdraw, PreviewWithdraw {
    using uMulDiv for uint256;

    function maxRedeem(WithdrawRedeemState memory state) public pure returns (uint256 max) {
        uint256 maxWithdrawAmount = maxWithdraw(state);
        (max,) = _previewWithdraw(maxWithdrawAmount, withdrawRedeemStateToData(state).vaultData);
    }
}
