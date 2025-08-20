// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceBorrowStateData} from "src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";
import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";

contract MaxLowLevelRebalanceBorrowStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceBorrowState() internal view returns (MaxLowLevelRebalanceBorrowStateData memory) {
        return MaxLowLevelRebalanceBorrowStateData({
            // round up to assume smaller border
            realBorrowAssets: getLendingConnector().getRealBorrowAssets(false, connectorGetterData),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            borrowPrice: oracleConnector.getPriceBorrowOracle()
        });
    }
}
