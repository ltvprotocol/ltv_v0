// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {ConvertCollateralData} from "src/structs/data/vault/ConvertCollateralData.sol";
import {VaultCollateral} from "src/math/VaultCollateral.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract ConvertToAssetsCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function convertToAssetsCollateral(uint256 shares, MaxGrowthFeeState memory state)
        external
        pure
        returns (uint256)
    {
        return _convertToAssetsCollateral(shares, maxGrowthFeeStateToConvertCollateralData(state));
    }

    function _convertToAssetsCollateral(uint256 shares, ConvertCollateralData memory data)
        public
        pure
        returns (uint256)
    {
        return shares.mulDivDown(data.totalAssetsCollateral, data.supplyAfterFee);
    }
}
