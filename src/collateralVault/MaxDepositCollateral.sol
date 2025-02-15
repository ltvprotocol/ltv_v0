// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../State.sol';
import '../utils/MulDiv.sol';
import '../Constants.sol';

abstract contract MaxDepositCollateral is State {
  using uMulDiv for uint256;

  function maxDepositCollateral(address) public view returns(uint256) {
    ConvertedAssets memory convertedAssets = recoverConvertedAssets();
    
    uint256 minProfitRealCollateral = uint256(convertedAssets.realBorrow).mulDivDown(Constants.LTV_DIVIDER, minProfitLTV);
    if (uint256(convertedAssets.realCollateral) >= minProfitRealCollateral) {
      return 0;
    }

    uint256 maxDepositInUnderlying = minProfitRealCollateral - uint256(convertedAssets.realCollateral);
    return maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
  }
}