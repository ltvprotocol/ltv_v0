// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../borrowVault/TotalAssets.sol';

abstract contract MaxWithdrawCollateral is TotalAssets {
  using uMulDiv for uint256;

  function maxWithdrawCollateral(address owner) public view returns(uint256) {
    ConvertedAssets memory convertedAssets = recoverConvertedAssets();
    uint256 maxSafeRealCollateral = uint256(convertedAssets.realBorrow).mulDivDown(Constants.LTV_DIVIDER, maxSafeLTV);
    if (uint256(convertedAssets.realCollateral) <= maxSafeRealCollateral) {
      return 0;
    }
    uint256 vaultMaxWithdrawInUnderlying = uint256(convertedAssets.realCollateral) - maxSafeRealCollateral;
    uint256 userBalanceInAssets = balanceOf[owner].mulDivDown(totalAssets(), totalSupply());
    uint256 userBalanceInUnderlying = userBalanceInAssets.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);

    uint256 maxWithdrawInUnderlying = vaultMaxWithdrawInUnderlying < userBalanceInUnderlying ? vaultMaxWithdrawInUnderlying : userBalanceInUnderlying;

    return maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
  }
}