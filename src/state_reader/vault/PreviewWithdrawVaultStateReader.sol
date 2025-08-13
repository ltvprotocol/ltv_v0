// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeStateReader.sol";
import "../../structs/state/vault/PreviewWithdrawVaultState.sol";

contract PreviewWithdrawVaultStateReader is MaxGrowthFeeStateReader {
    function previewWithdrawVaultState() internal view returns (PreviewWithdrawVaultState memory) {
        bytes memory _slippageProviderGetterData = slippageProviderGetterData;
        return PreviewWithdrawVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTVDividend: targetLTVDividend,
            targetLTVDivider: targetLTVDivider,
            startAuction: startAuction,
            auctionDuration: auctionDuration,
            blockNumber: uint56(block.number),
            collateralSlippage: slippageProvider.collateralSlippage(_slippageProviderGetterData),
            borrowSlippage: slippageProvider.borrowSlippage(_slippageProviderGetterData)
        });
    }
}
