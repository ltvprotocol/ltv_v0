// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {MaxLowLevelRebalanceSharesState} from "src/structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";

contract MaxLowLevelRebalanceSharesStateReader is MaxGrowthFeeStateReader {
    function maxLowLevelRebalanceSharesState() internal view returns (MaxLowLevelRebalanceSharesState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        return MaxLowLevelRebalanceSharesState({
            // overestimate assets for smaller border
            maxGrowthFeeState: maxGrowthFeeState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true, connectorGetterData),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true, connectorGetterData)
        });
    }
}
