// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './GetLendingConnectorReader.sol';
import 'src/structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol';

contract MaxLowLevelRebalanceBorrowStateReader is GetLendingConnectorReader {
    function maxLowLevelRebalanceBorrowState() internal view returns (MaxLowLevelRebalanceBorrowStateData memory) {
        return
            MaxLowLevelRebalanceBorrowStateData({
                realBorrowAssets: getLendingConnector().getRealBorrowAssets(),
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
                targetLTV: targetLTV,
                borrowPrice: oracleConnector.getPriceBorrowOracle()
            });
    }
}
