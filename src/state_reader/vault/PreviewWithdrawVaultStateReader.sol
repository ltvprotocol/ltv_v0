// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "../../structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxGrowthFeeStateReader} from "../common/MaxGrowthFeeStateReader.sol";

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
        bytes memory _slippageConnectorGetterData = slippageConnectorGetterData;
        return PreviewWithdrawVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
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
