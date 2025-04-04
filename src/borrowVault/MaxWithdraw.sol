// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';

abstract contract MaxWithdraw is MaxGrowthFee {
    using uMulDiv for uint256;

    function maxWithdraw(address owner) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets(false);
        // round down to assume smaller border
        uint256 maxSafeRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(maxSafeLTV, Constants.LTV_DIVIDER);
        if (maxSafeRealBorrow <= uint256(convertedAssets.realBorrow)) {
            return 0;
        }
        uint256 maxWithdrawInUnderlying = maxSafeRealBorrow - uint256(convertedAssets.realBorrow);
        // round down to assume smaller border
        uint256 vaultMaxWithdraw = maxWithdrawInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        // round down to assume smaller border
        uint256 userBalanceInAssets = balanceOf[owner].mulDivDown(_totalAssets(false), previewSupplyAfterFee());

        return userBalanceInAssets < vaultMaxWithdraw ? userBalanceInAssets : vaultMaxWithdraw;
    }
}
