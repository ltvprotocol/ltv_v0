// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/max/MaxLowLevelRebalanceCollateralStateData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxLowLevelRebalanceCollateral
 * @notice This contract contains max low level rebalance collateral function implementation.
 */
abstract contract MaxLowLevelRebalanceCollateral is MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @dev see ILowLevelRebalanceModule.maxLowLevelRebalanceCollateral
     */
    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory state)
        public
        pure
        returns (int256)
    {
        return _maxLowLevelRebalanceCollateral(state);
    }

    /**
     * @dev main function to calculate max low level rebalance collateral
     */
    function _maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory data)
        internal
        pure
        returns (int256)
    {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInCollateral =
            data.maxTotalAssetsInUnderlying.mulDivDown(10 ** data.collateralTokenDecimals, data.collateralPrice);
        // rounding down assuming smaller border
        uint256 maxCollateral = maxTotalAssetsInCollateral.mulDivDown(
            uint256(data.targetLtvDivider), uint256(data.targetLtvDivider - data.targetLtvDividend)
        );
        // casting to int256 is safe because maxCollateral and realCollateralAssets are considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return int256(maxCollateral) - int256(data.realCollateralAssets);
    }
}
