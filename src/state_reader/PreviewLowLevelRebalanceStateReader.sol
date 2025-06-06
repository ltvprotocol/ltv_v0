// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaxGrowthFeeStateReader.sol";
import "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

contract PreviewLowLevelRebalanceStateReader is MaxGrowthFeeStateReader {
    function previewLowLevelRebalanceState(bool isDeposit)
        internal
        view
        returns (PreviewLowLevelRebalanceState memory)
    {
        MaxGrowthFeeState memory maxGrowthFeeState = maxGrowthFeeState();
        ILendingConnector _lendingConnector = getLendingConnector();

        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState,
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true),
            targetLTV: targetLTV,
            blockNumber: block.number,
            startAuction: startAuction
        });
    }
}
