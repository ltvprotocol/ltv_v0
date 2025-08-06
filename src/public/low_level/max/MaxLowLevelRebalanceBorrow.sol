// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/Constants.sol";
import "src/utils/MulDiv.sol";
import "src/math/MaxGrowthFee.sol";
import "src/utils/MulDiv.sol";
import "src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";

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
            uint256(data.targetLTVDivider) * uint256(data.targetLTVDividend),
            uint256(data.targetLTVDivider - data.targetLTVDividend) * uint256(data.targetLTVDivider)
        );
        return int256(maxBorrow) - int256(data.realBorrowAssets);
    }
}
