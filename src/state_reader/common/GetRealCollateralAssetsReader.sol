// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../../math/abstracts/BoolReader.sol";
import {LTVState} from "../../states/LTVState.sol";

/**
 * @title GetRealCollateralAssetsReader
 * @notice contract contains functionality to retrieve real collateral assets
 * from the appropriate lending connector based on vault state
 */
contract GetRealCollateralAssetsReader is LTVState, BoolReader {
    /**
     * @dev see ILTV.getRealCollateralAssets
     */
    function _getRealCollateralAssets(bool isDeposit) internal view returns (uint256) {
        if (_isVaultDeleveraged(boolSlot)) {
            return vaultBalanceAsLendingConnector.getRealCollateralAssets(
                isDeposit, vaultBalanceAsLendingConnectorGetterData
            );
        }
        return lendingConnector.getRealCollateralAssets(isDeposit, lendingConnectorGetterData);
    }
}
