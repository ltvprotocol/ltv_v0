// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/Structs2.sol';
import 'src/Constants.sol';
import 'src/utils/MulDiv.sol';
import 'src/math2/MaxGrowthFee.sol';
import 'src/utils/MulDiv.sol';

contract MaxLowLevelRebalanceCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory state) public pure returns (int256) {
        return _maxLowLevelRebalanceCollateral(state);
    }

    function _maxLowLevelRebalanceCollateral(MaxLowLevelRebalanceCollateralStateData memory data) public pure returns (int256) {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInCollateral = data.maxTotalAssetsInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.collateralPrice);
        // rounding down assuming smaller border
        uint256 maxCollateral = maxTotalAssetsInCollateral.mulDivDown(Constants.LTV_DIVIDER, Constants.LTV_DIVIDER - data.targetLTV);
        return int256(maxCollateral) - int256(data.realCollateralAssets);
    }
}
