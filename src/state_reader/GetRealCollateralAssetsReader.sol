// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../state_reader/BoolReader.sol";

/**
 * @title GetRealCollateralAssetsReader
 * @notice contract contains functionality to retrieve real collateral assets
 * from the appropriate lending connector based on vault state
 */
contract GetRealCollateralAssetsReader is BoolReader {
    /**
     * @dev see ILTV.getRealCollateralAssets
     */
    function getRealCollateralAssets(bool isDeposit) public view returns (uint256) {
        if (isVaultDeleveraged()) {
            return vaultBalanceAsLendingConnector.getRealCollateralAssets(
                isDeposit, vaultBalanceAsLendingConnectorGetterData
            );
        }
        return lendingConnector.getRealCollateralAssets(isDeposit, lendingConnectorGetterData);
    }
}
