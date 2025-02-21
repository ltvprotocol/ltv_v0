// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxDepositCollateral.sol';
import './PreviewDepositCollateral.sol';

abstract contract MaxMintCollateral is MaxDepositCollateral, PreviewDepositCollateral {
  using uMulDiv for uint256;

  function maxMintCollateral(address receiver) public view returns(uint256) {
    uint256 maxDepositAssets = maxDepositCollateral(receiver);
    uint256 maxMintAssets = previewDepositCollateral(maxDepositAssets);
    return maxMintAssets;
  }
}