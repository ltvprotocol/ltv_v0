// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../state_reader/BoolReader.sol";

/**
 * @title GetRealBorrowAssetsReader
 * @notice contract contains functionality to retrieve real borrow assets
 * from the appropriate lending connector based on vault state
 */
contract GetRealBorrowAssetsReader is BoolReader {
    /**
     * @dev see ILTV.getRealBorrowAssets
     */
    function getRealBorrowAssets(bool isDeposit) public view returns (uint256) {
        if (isVaultDeleveraged()) {
            return
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData);
        }
        return lendingConnector.getRealBorrowAssets(isDeposit, lendingConnectorGetterData);
    }
}
