// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "../../../../../structs/state/common/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "../../../../../structs/data/common/MaxGrowthFeeData.sol";
import {MaxGrowthFee} from "../../../../../math/abstracts/MaxGrowthFee.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

abstract contract ConvertToAssets is MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.convertToAssets
     */
    function convertToAssets(uint256 shares, MaxGrowthFeeState memory state)
        external
        view
        virtual
        nonReentrantRead
        returns (uint256)
    {
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
