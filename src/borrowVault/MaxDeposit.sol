// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../State.sol';
import '../utils/MulDiv.sol';
import '../Constants.sol';

abstract contract MaxDeposit is State {
  using uMulDiv for uint256;

  function maxDeposit(address) public view returns(uint256) {
    ConvertedAssets memory convertedAssets = recoverConvertedAssets();
    
    uint256 minProfitRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(minProfitLTV, Constants.LTV_PRECISION);
    if (uint256(convertedAssets.realBorrow) <= minProfitRealBorrow) {
      return 0;
    }

    uint256 maxDepositInUnderlying = uint256(convertedAssets.realBorrow) - minProfitRealBorrow;
    return maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
  }
}