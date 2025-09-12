// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralStateToData} from
    "src/math/abstracts/state_to_data/max/MaxDepositMintCollateralStateToData.sol";
import {MaxWithdrawRedeemCollateralStateToData} from
    "src/math/abstracts/state_to_data/max/MaxWithdrawRedeemCollateralStateToData.sol";
import {MaxGrowthFeeStateToConvertCollateralData} from
    "src/math/abstracts/state_to_data/MaxGrowthFeeStateToConvertCollateralData.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title VaultCollateral
 * @notice Contract contains common functionality for all max collateral vault functions.
 */
abstract contract VaultCollateral is
    MaxDepositMintCollateralStateToData,
    MaxWithdrawRedeemCollateralStateToData,
    MaxGrowthFeeStateToConvertCollateralData
{
    using UMulDiv for uint256;

    /**
     * @notice Calculates available space according to maxTotalAssetsInUnderlying
     * constant. Return value is in shares because shares represent real difference
     * in total assets after user operation
     */
    function getAvailableSpaceInShares(
        int256 collateral,
        int256 borrow,
        uint256 maxTotalAssetsInUnderlying,
        uint256 supplyAfterFee,
        uint256 totalAssetsCollateral,
        uint256 collateralPrice,
        uint8 collateralTokenDecimals
    ) internal pure returns (uint256) {
        // casting to uint256 is safe because collateral is considered to be greater than borrow
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying).mulDivDown(
            10 ** collateralTokenDecimals, collateralPrice
        ).mulDivDown(supplyAfterFee, totalAssetsCollateral);

        return availableSpaceInShares;
    }
}
