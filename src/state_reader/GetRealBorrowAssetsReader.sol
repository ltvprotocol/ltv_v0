// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../math/abstracts/BoolReader.sol";
import {LTVState} from "../states/LTVState.sol";

contract GetRealBorrowAssetsReader is LTVState, BoolReader {
    function _getRealBorrowAssets(bool isDeposit) internal view returns (uint256) {
        if (_isVaultDeleveraged(boolSlot)) {
            return
                vaultBalanceAsLendingConnector.getRealBorrowAssets(isDeposit, vaultBalanceAsLendingConnectorGetterData);
        }
        return lendingConnector.getRealBorrowAssets(isDeposit, lendingConnectorGetterData);
    }
}
