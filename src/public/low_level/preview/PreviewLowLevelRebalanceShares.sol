// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;
import 'src/math/PreviewLowLevelRebalanceStateToData.sol';

abstract contract PreviewLowLevelRebalanceShares is PreviewLowLevelRebalanceStateToData {
    using uMulDiv for uint256;

    function previewLowLevelRebalanceShares(int256 deltaShares, PreviewLowLevelRebalanceState memory state) public pure returns (int256, int256) {
        (int256 deltaRealCollateral, int256 deltaRealBorrow, ) = _previewLowLevelRebalanceShares(
            deltaShares,
            previewLowLevelRebalanceStateToData(state, deltaShares >= 0)
        );
        return (deltaRealCollateral, deltaRealBorrow);
    }

    function _previewLowLevelRebalanceShares(int256 deltaShares, LowLevelRebalanceData memory data) internal pure returns (int256, int256, int256) {
        return LowLevelRebalanceMath.calculateLowLevelRebalanceShares(deltaShares, data);
    }
}
