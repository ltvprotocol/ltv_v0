// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "../../structs/state/common/MaxGrowthFeeState.sol";
import {PreviewLowLevelRebalanceState} from "../../structs/state/low_level/preview/PreviewLowLevelRebalanceState.sol";
import {MaxGrowthFeeStateReader} from "../common/MaxGrowthFeeStateReader.sol";

/**
 * @title PreviewLowLevelRebalanceStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * preview low level rebalance operations calculations
 */
contract PreviewLowLevelRebalanceStateReader is MaxGrowthFeeStateReader {
    /**
     * @dev function to retrieve pure state needed for preview low level rebalance operations
     */
    function previewLowLevelRebalanceState() internal view returns (PreviewLowLevelRebalanceState memory) {
        MaxGrowthFeeState memory maxGrowthFeeState = maxGrowthFeeState();
        (uint256 depositRealCollateralAssets, uint256 depositRealBorrowAssets) =
            getRealCollateralAndRealBorrowAssets(true);
        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState,
            depositRealBorrowAssets: depositRealBorrowAssets,
            depositRealCollateralAssets: depositRealCollateralAssets,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            blockNumber: uint56(block.number),
            startAuction: startAuction,
            auctionDuration: auctionDuration
        });
    }
}
