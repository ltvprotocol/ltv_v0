// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteLowLevelRebalanceState} from "src/structs/state/low_level/execute/ExecuteLowLevelRebalanceState.sol";
import {PreviewLowLevelRebalanceStateReader} from "src/state_reader/low_level/PreviewLowLevelRebalanceStateReader.sol";

contract ExecuteLowLevelRebalanceStateReader is PreviewLowLevelRebalanceStateReader {
    function executeLowLevelRebalanceState() internal view returns (ExecuteLowLevelRebalanceState memory) {
        return ExecuteLowLevelRebalanceState({
            previewLowLevelRebalanceState: previewLowLevelRebalanceState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
