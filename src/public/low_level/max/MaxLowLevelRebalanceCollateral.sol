// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";
import {MaxGrowthFee} from "src/math/MaxGrowthFee.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract MaxLowLevelRebalanceCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory state)
        public
        pure
        returns (int256)
    {
        return _maxLowLevelRebalanceCollateral(state);
    }

    function _maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory data)
        internal
        pure
        returns (int256)
    {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInCollateral =
            data.maxTotalAssetsInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.collateralPrice);
        // rounding down assuming smaller border
        uint256 maxCollateral = maxTotalAssetsInCollateral.mulDivDown(
            uint256(data.targetLtvDivider), uint256(data.targetLtvDivider - data.targetLtvDividend)
        );
        // casting to int256 is safe because maxCollateral and realCollateralAssets are considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return int256(maxCollateral) - int256(data.realCollateralAssets);
    }
}
