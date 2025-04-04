// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/MulDiv.sol";
import '../MaxGrowthFee.sol';

abstract contract ConvertToShares is MaxGrowthFee {

    using uMulDiv for uint256;

    function convertToShares(uint256 assets) external view virtual returns (uint256) {
        // count with deposit
        // return assets.mulDivDown(previewSupplyAfterFee(), _totalAssets(true));
        // count with withdraw
        return assets.mulDivUp(previewSupplyAfterFee(), _totalAssets(false));
    }
}