// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/preview/PreviewLowLevelRebalanceState.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {PreviewLowLevelRebalanceStateToData} from
    "src/math/abstracts/state_to_data/preview/PreviewLowLevelRebalanceStateToData.sol";
import {LowLevelRebalanceMath} from "src/math/libraries/LowLevelRebalanceMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title PreviewLowLevelRebalanceShares
 * @notice This contract contains preview low level rebalance shares function implementation.
 */
abstract contract PreviewLowLevelRebalanceShares is PreviewLowLevelRebalanceStateToData {
    using UMulDiv for uint256;

    /**
     * @dev see ILowLevelRebalanceModule.previewLowLevelRebalanceShares
     */
    function previewLowLevelRebalanceShares(int256 deltaShares, PreviewLowLevelRebalanceState memory state)
        public
        view
        nonReentrantRead
        returns (int256, int256)
    {
        (int256 deltaRealCollateral, int256 deltaRealBorrow,) =
            _previewLowLevelRebalanceShares(deltaShares, previewLowLevelRebalanceStateToData(state, deltaShares >= 0));
        return (deltaRealCollateral, deltaRealBorrow);
    }

    /**
     * @dev base function to calculate preview low level rebalance shares
     */
    function _previewLowLevelRebalanceShares(int256 deltaShares, LowLevelRebalanceData memory data)
        internal
        pure
        returns (int256, int256, int256)
    {
        return LowLevelRebalanceMath.calculateLowLevelRebalanceShares(deltaShares, data);
    }
}
