// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {LTVState} from "src/states/LTVState.sol";
import {BoolReader} from "src/state_reader/BoolReader.sol";

/**
 * @title GetLendingConnectorReader
 * @notice contract contains functionality to retrieve the appropriate lending connector
 * based on vault state (deleveraged or normal operation)
 */
contract GetLendingConnectorReader is LTVState, BoolReader {
    /**
     * @dev @see ILTV.getLendingConnector
     */
    function getLendingConnector() public view returns (ILendingConnector) {
        return isVaultDeleveraged() ? vaultBalanceAsLendingConnector : lendingConnector;
    }
}
