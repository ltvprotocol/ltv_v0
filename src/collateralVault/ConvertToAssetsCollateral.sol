// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../MaxGrowthFee.sol';
import "../utils/MulDiv.sol";

abstract contract ConvertToAssetsCollateral is MaxGrowthFee {

    using uMulDiv for uint256;

    function convertToAssetsCollateral(uint256 shares) external view virtual returns (uint256) {
        // assume smaller token price
        return shares.mulDivDown(totalAssetsCollateral(), previewSupplyAfterFee());
    }
}