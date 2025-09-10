// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract ConvertToAssets is MaxGrowthFee {
    using uMulDiv for uint256;

    function convertToAssets(uint256 shares, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        // count with withdraw
        return _convertToAssets(shares, maxGrowthFeeStateToData(state));
    }

    function _convertToAssets(uint256 shares, MaxGrowthFeeData memory data) internal view virtual returns (uint256) {
        return shares.mulDivDown(data.withdrawTotalAssets, _previewSupplyAfterFee(data));
    }
}
