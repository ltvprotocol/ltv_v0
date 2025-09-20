// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../../math/abstracts/BoolReader.sol";
import {LTVState} from "../../states/LTVState.sol";

/**
 * @title GetRealBorrowAssetsReader
 * @notice contract contains functionality to retrieve real borrow assets
 * from the appropriate lending connector based on vault state
 */
contract GetRealBorrowAssetsReader is LTVState, BoolReader {
    /**
     * @dev see ILTV.getRealBorrowAssets
     */
    function _getRealBorrowAssets(bool isDeposit) internal view returns (uint256) {
        if (_isVaultDeleveraged(boolSlot)) {
            return
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData);
        }
        return lendingConnector.getRealBorrowAssets(isDeposit, lendingConnectorGetterData);
    }
}
