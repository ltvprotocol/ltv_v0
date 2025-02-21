// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxWithdrawCollateral.sol';
import './PreviewWithdrawCollateral.sol';

abstract contract MaxRedeemCollateral is MaxWithdrawCollateral, PreviewWithdrawCollateral {
  using uMulDiv for uint256;
  function maxRedeemCollateral(address owner) public view returns(uint256) {
    uint256 maxWithdraw = maxWithdrawCollateral(owner);
    return previewWithdrawCollateral(maxWithdraw);
  }
}