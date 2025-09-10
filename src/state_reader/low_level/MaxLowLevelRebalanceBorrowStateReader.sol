// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceBorrowStateData} from "src/structs/state/low_level/max/MaxLowLevelRebalanceBorrowStateData.sol";
import {GetRealBorrowAssetsReader} from "../common/GetRealBorrowAssetsReader.sol";

contract MaxLowLevelRebalanceBorrowStateReader is GetRealBorrowAssetsReader {
    function maxLowLevelRebalanceBorrowState() internal view returns (MaxLowLevelRebalanceBorrowStateData memory) {
        return MaxLowLevelRebalanceBorrowStateData({
            // round up to assume smaller border
            realBorrowAssets: _getRealBorrowAssets(false),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            borrowPrice: oracleConnector.getPriceBorrowOracle(oracleConnectorGetterData)
        });
    }
}
