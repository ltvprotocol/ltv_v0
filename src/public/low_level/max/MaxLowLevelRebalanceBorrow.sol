// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxLowLevelRebalanceBorrowStateData} from "src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";
import {MaxGrowthFee} from "src/math/MaxGrowthFee.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract MaxLowLevelRebalanceBorrow is MaxGrowthFee {
    using uMulDiv for uint256;

    function maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory state)
        public
        pure
        returns (int256)
    {
        return _maxLowLevelRebalanceBorrow(state);
    }

    function _maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory data)
        public
        pure
        returns (int256)
    {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInBorrow =
            data.maxTotalAssetsInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.borrowPrice);
        // rounding down assuming smaller border
        uint256 maxBorrow = maxTotalAssetsInBorrow.mulDivDown(
            uint256(data.targetLtvDivider) * uint256(data.targetLtvDividend),
            uint256(data.targetLtvDivider - data.targetLtvDividend) * uint256(data.targetLtvDivider)
        );
        return int256(maxBorrow) - int256(data.realBorrowAssets);
    }
}
