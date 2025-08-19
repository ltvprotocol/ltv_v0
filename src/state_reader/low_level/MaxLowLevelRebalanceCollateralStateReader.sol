// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceCollateralStateData} from
    "src/structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";
import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";

contract MaxLowLevelRebalanceCollateralStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceCollateralState()
        internal
        view
        returns (MaxLowLevelRebalanceCollateralStateData memory)
    {
        return MaxLowLevelRebalanceCollateralStateData({
            // round up to assume smaller border
            realCollateralAssets: getLendingConnector().getRealCollateralAssets(true, lendingConnectorGetterData),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            collateralPrice: oracleConnector.getPriceCollateralOracle(oracleConnectorGetterData)
        });
    }
}
