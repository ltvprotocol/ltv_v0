// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaxGrowthFeeStateReader.sol";
import "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

contract PreviewLowLevelRebalanceStateReader is MaxGrowthFeeStateReader {
    function previewLowLevelRebalanceState() internal view returns (PreviewLowLevelRebalanceState memory) {
        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTV: targetLTV,
            blockNumber: block.number,
            startAuction: startAuction
        });
    }
}
