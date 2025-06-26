// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/math/VaultCollateral.sol";

abstract contract ConvertToSharesCollateral is VaultCollateral {
    using uMulDiv for uint256;

    function convertToSharesCollateral(uint256 assets, MaxGrowthFeeState memory state)
        external
        pure
        returns (uint256)
    {
        return _convertToSharesCollateral(assets, maxGrowthFeeStateToConvertCollateralData(state));
    }

    function _convertToSharesCollateral(uint256 assets, ConvertCollateralData memory data)
        public
        pure
        returns (uint256)
    {
        return assets.mulDivDown(data.supplyAfterFee, data.totalAssetsCollateral);
    }
}
