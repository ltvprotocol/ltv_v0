// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LendingConnectorState} from "src/structs/state/LendingConnectorState.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title GetLendingConnectorStateReader
 * @notice contract contains functionality to retrieve state related to lending connector
 */
abstract contract GetLendingConnectorStateReader is LTVState {
    /**
     * @notice function to get the lending connector state
     */
    function getLendingConnectorState() internal view returns (LendingConnectorState memory) {
        return LendingConnectorState({
            boolSlot: boolSlot,
            lendingConnector: address(lendingConnector),
            vaultBalanceAsLendingConnector: address(vaultBalanceAsLendingConnector)
        });
    }
}
