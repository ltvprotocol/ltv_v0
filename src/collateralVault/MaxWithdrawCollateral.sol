// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';

abstract contract MaxWithdrawCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function maxWithdrawCollateral(address owner) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets(false);
        // round up to assume smaller border
        uint256 maxSafeRealCollateral = uint256(convertedAssets.realBorrow).mulDivUp(Constants.LTV_DIVIDER, maxSafeLTV);
        if (uint256(convertedAssets.realCollateral) <= maxSafeRealCollateral) {
            return 0;
        }
        uint256 vaultMaxWithdrawInUnderlying = uint256(convertedAssets.realCollateral) - maxSafeRealCollateral;
        // round down to assume smaller border
        uint256 userBalanceInUnderlying = balanceOf[owner].mulDivDown(totalAssets(), previewSupplyAfterFee()).mulDivDown(
            getPriceBorrowOracle(),
            Constants.ORACLE_DIVIDER
        );

        uint256 maxWithdrawInUnderlying = vaultMaxWithdrawInUnderlying < userBalanceInUnderlying
            ? vaultMaxWithdrawInUnderlying
            : userBalanceInUnderlying;

        // round up to burn more shares
        return maxWithdrawInUnderlying.mulDivUp(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
    }
}
