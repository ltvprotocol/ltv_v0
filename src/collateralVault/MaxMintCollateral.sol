// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './MaxDepositCollateral.sol';
import './PreviewDepositCollateral.sol';

abstract contract MaxMint is MaxDepositCollateral, PreviewDepositCollateral {
  using uMulDiv for uint256;

  function maxMint(address receiver) public view returns(uint256) {
    uint256 maxDepositAssets = maxDepositCollateral(receiver);
    uint256 maxMintAssets = previewDepositCollateral(maxDepositAssets);
    return maxMintAssets;
  }
}