// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title ConvertToShares
 * @notice This contract contains convert to shares function implementation.
 */
abstract contract ConvertToShares is MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.convertToShares
     */
    function convertToShares(uint256 assets, MaxGrowthFeeState memory state) external view virtual returns (uint256) {
        return _convertToShares(assets, maxGrowthFeeStateToData(state));
    }

    /**
     * @dev base function to calculate convert to shares
     */
    function _convertToShares(uint256 assets, MaxGrowthFeeData memory data) internal view virtual returns (uint256) {
        return assets.mulDivDown(_previewSupplyAfterFee(data), data.withdrawTotalAssets);
    }
}
