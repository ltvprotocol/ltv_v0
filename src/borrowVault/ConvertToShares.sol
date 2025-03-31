// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/MulDiv.sol";
import '../MaxGrowthFee.sol';

abstract contract ConvertToShares is MaxGrowthFee {

    using uMulDiv for uint256;

    function convertToShares(uint256 assets) external view virtual returns (uint256) {
        // overestimate total assets and round up to assume lower token price
        return assets.mulDivUp(previewSupplyAfterFee(), _totalAssets(true));
    }
}