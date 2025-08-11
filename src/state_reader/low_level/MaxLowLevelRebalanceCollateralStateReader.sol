// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../GetLendingConnectorReader.sol";
import "src/structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";

contract MaxLowLevelRebalanceCollateralStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceCollateralState()
        internal
        view
        returns (MaxLowLevelRebalanceCollateralStateData memory)
    {
        return MaxLowLevelRebalanceCollateralStateData({
            // round up to assume smaller border
            realCollateralAssets: getLendingConnector().getRealCollateralAssets(true, connectorGetterData),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLTVDividend: targetLTVDividend,
            targetLTVDivider: targetLTVDivider,
            collateralPrice: oracleConnector.getPriceCollateralOracle()
        });
    }
}
