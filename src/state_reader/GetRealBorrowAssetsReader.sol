// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../state_reader/BoolReader.sol";

contract GetRealBorrowAssetsReader is BoolReader {
    function getRealBorrowAssets(bool isDeposit) public view returns (uint256) {
        if (isVaultDeleveraged()) {
            return
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData);
        }
        return lendingConnector.getRealBorrowAssets(isDeposit, lendingConnectorGetterData);
    }
}
