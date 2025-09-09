// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../interfaces/connectors/ILendingConnector.sol";
import {BoolReader} from "../math/abstracts/BoolReader.sol";
import {LTVState} from "../states/LTVState.sol";

contract GetRealCollateralAndRealBorrowAssetsReader is LTVState, BoolReader {
    function getRealCollateralAndRealBorrowAssets(bool isDeposit) internal view returns (uint256, uint256) {
        if (_isVaultDeleveraged(boolSlot)) {
            return (
                vaultBalanceAsLendingConnector.getRealCollateralAssets(
                    isDeposit, vaultBalanceAsLendingConnectorGetterData
                ),
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData)
            );
        }
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        ILendingConnector _lendingConnector = lendingConnector;
        return (
            _lendingConnector.getRealCollateralAssets(isDeposit, _lendingConnectorGetterData),
            _lendingConnector.getRealBorrowAssets(isDeposit, _lendingConnectorGetterData)
        );
    }
}
