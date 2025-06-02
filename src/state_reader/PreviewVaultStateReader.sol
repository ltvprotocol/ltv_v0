// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaxGrowthFeeStateReader.sol";
import "src/structs/state/vault/PreviewVaultState.sol";

contract PreviewVaultStateReader is MaxGrowthFeeStateReader {
    function previewVaultState() internal view returns (PreviewVaultState memory) {
        return PreviewVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTV: targetLTV,
            startAuction: startAuction,
            blockNumber: block.number,
            collateralSlippage: slippageProvider.collateralSlippage(),
            borrowSlippage: slippageProvider.borrowSlippage()
        });
    }
}
