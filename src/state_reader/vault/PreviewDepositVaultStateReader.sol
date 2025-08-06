// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeStateReader.sol";
import "../../structs/state/vault/PreviewDepositVaultState.sol";

contract PreviewDepositVaultStateReader is MaxGrowthFeeStateReader {
    function previewDepositVaultState() internal view returns (PreviewDepositVaultState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        return PreviewDepositVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true, connectorGetterData),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true, connectorGetterData),
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
