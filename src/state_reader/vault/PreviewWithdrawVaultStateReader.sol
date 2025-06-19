// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeStateReader.sol";
import "../../structs/state/vault/PreviewWithdrawVaultState.sol";

contract PreviewWithdrawVaultStateReader is MaxGrowthFeeStateReader {
    function previewWithdrawVaultState() internal view returns (PreviewWithdrawVaultState memory) {
        return PreviewWithdrawVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTV: targetLTV,
            startAuction: startAuction,
            blockNumber: block.number,
            collateralSlippage: slippageProvider.collateralSlippage(),
            borrowSlippage: slippageProvider.borrowSlippage()
        });
    }
}
