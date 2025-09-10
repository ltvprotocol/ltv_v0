// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../../../math/abstracts/BoolReader.sol";
import {LendingConnectorState} from "../../../structs/state/common/LendingConnectorState.sol";

/**
 * @title GetLendingConnector
 * @notice This contract is used to get current lending connector.
 * @dev It can be changed due to emergency deleverage.
 */
contract GetLendingConnector is BoolReader {
    /**
     * @notice Get current lending connector
     * @dev It can be changed due to emergency deleverage.
     */
    function getLendingConnector(LendingConnectorState memory state) public pure returns (address) {
        return _isVaultDeleveraged(state.boolSlot) ? state.vaultBalanceAsLendingConnector : state.lendingConnector;
    }
}
