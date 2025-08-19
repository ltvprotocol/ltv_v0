// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";

contract PreviewLowLevelRebalanceStateReader is MaxGrowthFeeStateReader {
    function previewLowLevelRebalanceState() internal view returns (PreviewLowLevelRebalanceState memory) {
        MaxGrowthFeeState memory maxGrowthFeeState = maxGrowthFeeState();
        ILendingConnector _lendingConnector = getLendingConnector();
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState,
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true, _lendingConnectorGetterData),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true, _lendingConnectorGetterData),
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            blockNumber: uint56(block.number),
            startAuction: startAuction,
            auctionDuration: auctionDuration
        });
    }
}
