// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './MaxDeposit.sol';
import './PreviewDeposit.sol';

abstract contract MaxMint is MaxDeposit, PreviewDeposit {
  using uMulDiv for uint256;

  function maxMint(address receiver) public view returns(uint256) {
    uint256 maxDepositAssets = maxDeposit(receiver);
    uint256 maxMintAssets = previewDeposit(maxDepositAssets);
    return maxMintAssets;
  }
}