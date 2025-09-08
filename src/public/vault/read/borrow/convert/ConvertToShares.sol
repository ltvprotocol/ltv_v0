// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract ConvertToShares is MaxGrowthFee {
    using uMulDiv for uint256;

    function convertToShares(uint256 assets, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        return _convertToShares(assets, maxGrowthFeeStateToData(state));
    }

    function _convertToShares(uint256 assets, MaxGrowthFeeData memory data) internal view virtual returns (uint256) {
        return assets.mulDivDown(_previewSupplyAfterFee(data), data.withdrawTotalAssets);
    }
}
