// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../GetLendingConnectorReader.sol";
import "src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";

contract MaxLowLevelRebalanceBorrowStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceBorrowState() internal view returns (MaxLowLevelRebalanceBorrowStateData memory) {
        return MaxLowLevelRebalanceBorrowStateData({
            // round up to assume smaller border
            realBorrowAssets: getLendingConnector().getRealBorrowAssets(false, connectorGetterData),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLTVDividend: targetLTVDividend,
            targetLTVDivider: targetLTVDivider,
            borrowPrice: oracleConnector.getPriceBorrowOracle()
        });
    }
}
