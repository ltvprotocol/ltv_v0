// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxWithdraw.sol';
import './PreviewWithdraw.sol';

abstract contract MaxRedeem is MaxWithdraw, PreviewWithdraw {
  using uMulDiv for uint256;
  function maxRedeem(address owner) public view returns(uint256) {
    uint256 maxWithdraw = maxWithdraw(owner);
    return previewWithdraw(maxWithdraw);
  }
}