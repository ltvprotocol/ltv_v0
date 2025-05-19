// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './GetLendingConnectorReader.sol';
import 'src/structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol';

contract MaxLowLevelRebalanceCollateralStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceCollateralState() internal view returns (MaxLowLevelRebalanceCollateralStateData memory) {
        return
            MaxLowLevelRebalanceCollateralStateData({
                realCollateralAssets: getLendingConnector().getRealCollateralAssets(),
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
                targetLTV: targetLTV,
                collateralPrice: oracleConnector.getPriceCollateralOracle()
            });
    }
}
