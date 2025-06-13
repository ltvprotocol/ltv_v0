// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./state_to_data/max/MaxDepositMintCollateralStateToData.sol";
import "./state_to_data/max/MaxWithdrawRedeemCollateralStateToData.sol";
import "./state_to_data/MaxGrowthFeeStateToConvertCollateralData.sol";

abstract contract VaultCollateral is
    MaxDepositMintCollateralStateToData,
    MaxWithdrawRedeemCollateralStateToData,
    MaxGrowthFeeStateToConvertCollateralData
{
    using uMulDiv for uint256;

    function getAvailableSpaceInShares(
        int256 collateral,
        int256 borrow,
        uint256 maxTotalAssetsInUnderlying,
        uint256 supplyAfterFee,
        uint256 totalAssetsCollateral,
        uint256 collateralPrice
    ) internal pure returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying).mulDivDown(
            Constants.ORACLE_DIVIDER, collateralPrice
        ).mulDivDown(supplyAfterFee, totalAssetsCollateral);

        return availableSpaceInShares;
    }
}
