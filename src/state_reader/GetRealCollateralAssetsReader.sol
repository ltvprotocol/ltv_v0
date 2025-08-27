// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../state_reader/BoolReader.sol";

contract GetRealCollateralAssetsReader is BoolReader {
    function getRealCollateralAssets(bool isDeposit) public view returns (uint256) {
        if (isVaultDeleveraged()) {
            return vaultBalanceAsLendingConnector.getRealCollateralAssets(
                isDeposit, vaultBalanceAsLendingConnectorGetterData
            );
        }
        return lendingConnector.getRealCollateralAssets(isDeposit, lendingConnectorGetterData);
    }
}
