// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './MaxRedeem.sol';
import './PreviewRedeem.sol';

abstract contract MaxWithdraw is MaxRedeem, PreviewRedeem {
  using uMulDiv for uint256;

  function maxWithdraw(address owner) public view returns(uint256) {
    uint256 maxRedeem = maxRedeem(owner);
    return previewRedeem(maxRedeem);
  }
}