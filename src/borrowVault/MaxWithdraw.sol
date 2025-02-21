// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './TotalAssets.sol';

abstract contract MaxWithdraw is TotalAssets {
  using uMulDiv for uint256;

  function maxWithdraw(address owner) public view returns(uint256) {
    ConvertedAssets memory convertedAssets = recoverConvertedAssets();
    uint256 maxSafeRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(maxSafeLTV, Constants.LTV_DIVIDER);
    if (maxSafeRealBorrow <= uint256(convertedAssets.realBorrow)) {
      return 0;
    }
    uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(convertedAssets.realBorrow);
    uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
    uint256 userBalanceInAssets = balanceOf[owner].mulDivDown(totalAssets(), totalSupply());

    return userBalanceInAssets < vaultMaxWithdraw ? userBalanceInAssets : vaultMaxWithdraw;
  }
}