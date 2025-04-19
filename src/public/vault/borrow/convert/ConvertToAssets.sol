// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';

abstract contract ConvertToAssets is MaxGrowthFee {
    using uMulDiv for uint256;

    function convertToAssets(uint256 shares, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        // count with withdraw
        return shares.mulDivDown(totalAssets(false, state.totalAssetsState), previewSupplyAfterFee(state));
    }
}
