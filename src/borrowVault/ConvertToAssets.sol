// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';
import "../utils/MulDiv.sol";

abstract contract ConvertToAssets is MaxGrowthFee {

    using uMulDiv for uint256;

    function convertToAssets(uint256 shares) external view virtual returns (uint256) {
        // underestimate total assets and round down to assume lower token price
        return shares.mulDivDown(_totalAssets(false), previewSupplyAfterFee());
    }
}