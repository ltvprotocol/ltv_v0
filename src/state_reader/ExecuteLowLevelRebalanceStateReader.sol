// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewLowLevelRebalanceStateReader.sol';
import 'src/structs/state/low_level/ExecuteLowLevelRebalanceState.sol';

contract ExecuteLowLevelRebalanceStateReader is PreviewLowLevelRebalanceStateReader {
    function executeLowLevelRebalanceState() internal view returns (ExecuteLowLevelRebalanceState memory) {
        return
            ExecuteLowLevelRebalanceState({
                previewLowLevelRebalanceState: previewLowLevelRebalanceState(),
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }
}
