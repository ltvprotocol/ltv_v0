// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';

abstract contract ConvertToShares is MaxGrowthFee {
    using uMulDiv for uint256;

    function convertToShares(uint256 assets, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        return assets.mulDivDown(previewSupplyAfterFee(state), totalAssets(false, state.totalAssetsState));
    }
}
