// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";

/**
 * @title PreviewWithdrawVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * preview withdraw vault operations calculations
 */
contract PreviewWithdrawVaultStateReader is MaxGrowthFeeStateReader {
    /**
     * @dev function to retrieve pure state needed for preview withdraw vault
     */
    function previewWithdrawVaultState() internal view returns (PreviewWithdrawVaultState memory) {
        bytes memory _slippageProviderGetterData = slippageProviderGetterData;
        return PreviewWithdrawVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLtvDividend: targetLtvDividend,
            targetLtvDivider: targetLtvDivider,
            startAuction: startAuction,
            auctionDuration: auctionDuration,
            blockNumber: uint56(block.number),
            collateralSlippage: slippageProvider.collateralSlippage(_slippageProviderGetterData),
            borrowSlippage: slippageProvider.borrowSlippage(_slippageProviderGetterData)
        });
    }
}
