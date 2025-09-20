// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/common/MaxGrowthFeeStateReader.sol";

/**
 * @title PreviewDepositVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * preview deposit vault calculations
 */
contract PreviewDepositVaultStateReader is MaxGrowthFeeStateReader {
    /**
     * @dev function to retrieve pure state needed for preview deposit vault
     */
    function previewDepositVaultState() internal view returns (PreviewDepositVaultState memory) {
        (uint256 depositRealCollateralAssets, uint256 depositRealBorrowAssets) =
            getRealCollateralAndRealBorrowAssets(true);
        bytes memory _slippageConnectorGetterData = slippageConnectorGetterData;
        return PreviewDepositVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            depositRealBorrowAssets: depositRealBorrowAssets,
            depositRealCollateralAssets: depositRealCollateralAssets,
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            startAuction: startAuction,
            auctionDuration: auctionDuration,
            blockNumber: uint56(block.number),
            collateralSlippage: slippageConnector.collateralSlippage(_slippageConnectorGetterData),
            borrowSlippage: slippageConnector.borrowSlippage(_slippageConnectorGetterData)
        });
    }
}
