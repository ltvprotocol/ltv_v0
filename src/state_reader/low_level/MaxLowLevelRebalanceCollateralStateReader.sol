// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/max/MaxLowLevelRebalanceCollateralStateData.sol";
import {GetRealCollateralAssetsReader} from "../common/GetRealCollateralAssetsReader.sol";

/**
 * @title MaxLowLevelRebalanceCollateralStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max low level rebalance collateral calculations
 */
contract MaxLowLevelRebalanceCollateralStateReader is GetRealCollateralAssetsReader {
    /**
     * @dev function to retrieve pure state needed for max low level rebalance collateral
     */
    function maxLowLevelRebalanceCollateralState()
        internal
        view
        returns (MaxLowLevelRebalanceCollateralStateData memory)
    {
        return MaxLowLevelRebalanceCollateralStateData({
            // round up to assume smaller border
            realCollateralAssets: _getRealCollateralAssets(true),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            collateralPrice: oracleConnector.getPriceCollateralOracle(oracleConnectorGetterData),
            collateralTokenDecimals: collateralTokenDecimals
        });
    }
}
