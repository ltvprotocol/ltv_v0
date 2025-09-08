// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {LTVState} from "src/states/LTVState.sol";
import {BoolReader} from "src/state_reader/BoolReader.sol";

contract GetLendingConnectorReader is LTVState, BoolReader {
    function getLendingConnector() public view returns (ILendingConnector) {
        return isVaultDeleveraged() ? vaultBalanceAsLendingConnector : lendingConnector;
    }
}
