// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../interfaces/ILendingConnector.sol";
import {GetLendingConnectorReader} from "../state_reader/GetLendingConnectorReader.sol";

contract GetRealCollateralAndRealBorrowAssetsReader is GetLendingConnectorReader {
    function getRealCollateralAndRealBorrowAssets(bool isDeposit) internal view returns (uint256, uint256) {
        if (isVaultDeleveraged()) {
            return (
                vaultBalanceAsLendingConnector.getRealCollateralAssets(
                    isDeposit, vaultBalanceAsLendingConnectorGetterData
                ),
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData)
            );
        }
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        ILendingConnector _lendingConnector = getLendingConnector();
        return (
            _lendingConnector.getRealCollateralAssets(isDeposit, _lendingConnectorGetterData),
            _lendingConnector.getRealBorrowAssets(isDeposit, _lendingConnectorGetterData)
        );
    }
}
