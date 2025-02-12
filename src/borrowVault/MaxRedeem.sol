// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../utils/MulDiv.sol';
import './TotalAssets.sol';

abstract contract MaxRedeem is TotalAssets {
  using uMulDiv for uint256;
  function maxRedeem(address owner) public view returns(uint256) {
    ConvertedAssets memory convertedAssets = recoverConvertedAssets();
    uint256 maxSafeRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(maxSafeLTV, Constants.LTV_DIVIDER);
    if (maxSafeRealBorrow <= uint256(convertedAssets.realBorrow)) {
      return 0;
    }
    uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(convertedAssets.realBorrow);
    uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
    uint256 vaultMaxWithdrawInShares = vaultMaxWithdraw.mulDivUp(totalSupply(), totalAssets());
    uint256 userBalance = balanceOf[owner];

    return userBalance < vaultMaxWithdrawInShares ? userBalance : vaultMaxWithdrawInShares;
  }
}