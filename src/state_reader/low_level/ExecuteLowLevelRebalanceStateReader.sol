// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ExecuteLowLevelRebalanceState} from "../../structs/state/low_level/execute/ExecuteLowLevelRebalanceState.sol";
import {PreviewLowLevelRebalanceStateReader} from "PreviewLowLevelRebalanceStateReader.sol";

/**
 * @title ExecuteLowLevelRebalanceStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * execute low level rebalance functions calculations
 */
contract ExecuteLowLevelRebalanceStateReader is PreviewLowLevelRebalanceStateReader {
    /**
     * @dev function to retrieve pure state needed for execute low level rebalance functions calculations
     */
    function executeLowLevelRebalanceState() internal view returns (ExecuteLowLevelRebalanceState memory) {
        return ExecuteLowLevelRebalanceState({
            previewLowLevelRebalanceState: previewLowLevelRebalanceState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
