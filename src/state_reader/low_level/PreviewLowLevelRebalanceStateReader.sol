// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeStateReader.sol";
import "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

contract PreviewLowLevelRebalanceStateReader is MaxGrowthFeeStateReader {
    function previewLowLevelRebalanceState() internal view returns (PreviewLowLevelRebalanceState memory) {
        MaxGrowthFeeState memory maxGrowthFeeState = maxGrowthFeeState();
        ILendingConnector _lendingConnector = getLendingConnector();

        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState,
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true, connectorGetterData),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true, connectorGetterData),
            targetLTVDividend: targetLTVDividend,
            targetLTVDivider: targetLTVDivider,
            blockNumber: uint56(block.number),
            startAuction: startAuction,
            auctionDuration: auctionDuration
        });
    }
}
