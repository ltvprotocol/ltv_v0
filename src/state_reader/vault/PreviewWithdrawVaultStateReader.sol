// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/common/MaxGrowthFeeStateReader.sol";

contract PreviewWithdrawVaultStateReader is MaxGrowthFeeStateReader {
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
