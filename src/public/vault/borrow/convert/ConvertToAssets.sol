// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "src/math/MaxGrowthFee.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract ConvertToAssets is MaxGrowthFee {
    using uMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.convertToAssets
     */
    function convertToAssets(uint256 shares, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        // count with withdraw
        return _convertToAssets(shares, maxGrowthFeeStateToData(state));
    }

    /**
     * @dev base function to calculate convert to assets
     */
    function _convertToAssets(uint256 shares, MaxGrowthFeeData memory data) internal view virtual returns (uint256) {
        return shares.mulDivDown(data.withdrawTotalAssets, _previewSupplyAfterFee(data));
    }
}
