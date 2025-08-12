// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeStateReader.sol";
import "../../structs/state/vault/PreviewDepositVaultState.sol";

contract PreviewDepositVaultStateReader is MaxGrowthFeeStateReader {
    function previewDepositVaultState() internal view returns (PreviewDepositVaultState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        bytes memory _slippageProviderGetterData = slippageProviderGetterData;
        return PreviewDepositVaultState({
            maxGrowthFeeState: maxGrowthFeeState(),
            depositRealBorrowAssets: _lendingConnector.getRealBorrowAssets(true, _lendingConnectorGetterData),
            depositRealCollateralAssets: _lendingConnector.getRealCollateralAssets(true, _lendingConnectorGetterData),
            targetLTV: targetLTV,
            startAuction: startAuction,
            blockNumber: block.number,
            collateralSlippage: slippageProvider.collateralSlippage(_slippageProviderGetterData),
            borrowSlippage: slippageProvider.borrowSlippage(_slippageProviderGetterData)
        });
    }
}
