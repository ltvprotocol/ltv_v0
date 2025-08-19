// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";

contract PreviewWithdrawVaultStateReader is MaxGrowthFeeStateReader {
    function previewWithdrawVaultState() internal view returns (PreviewWithdrawVaultState memory) {
        return PreviewWithdrawVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTVDividend: targetLTVDividend,
            targetLTVDivider: targetLTVDivider,
            startAuction: startAuction,
            auctionDuration: auctionDuration,
            blockNumber: uint56(block.number),
            collateralSlippage: slippageProvider.collateralSlippage(),
            borrowSlippage: slippageProvider.borrowSlippage()
        });
    }
}
