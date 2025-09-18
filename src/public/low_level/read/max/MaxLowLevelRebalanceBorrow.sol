// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceBorrowStateData} from
    "src/structs/state/low_level/max/MaxLowLevelRebalanceBorrowStateData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

abstract contract MaxLowLevelRebalanceBorrow is MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @dev see ILowLevelRebalanceModule.maxLowLevelRebalanceBorrow
     */
    function maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory state)
        public
        pure
        returns (int256)
    {
        return _maxLowLevelRebalanceBorrow(state);
    }

    /**
     * @dev main function to calculate max low level rebalance borrow
     */
    function _maxLowLevelRebalanceBorrow(MaxLowLevelRebalanceBorrowStateData memory data)
        internal
        pure
        returns (int256)
    {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInBorrow =
            data.maxTotalAssetsInUnderlying.mulDivDown(10 ** data.borrowTokenDecimals, data.borrowPrice);
        // rounding down assuming smaller border
        uint256 maxBorrow = maxTotalAssetsInBorrow.mulDivDown(
            uint256(data.targetLtvDividend), uint256(data.targetLtvDivider - data.targetLtvDividend)
        );
        // casting to int256 is safe because maxBorrow and realBorrowAssets are considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return int256(maxBorrow) - int256(data.realBorrowAssets);
    }
}
