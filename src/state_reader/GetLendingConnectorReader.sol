// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/states/LTVState.sol";
import "src/interfaces/ILendingConnector.sol";
import "src/state_reader/BoolReader.sol";

contract GetLendingConnectorReader is LTVState, BoolReader {
    function getLendingConnector() public view returns (ILendingConnector) {
        return isVaultDeleveraged() ? vaultBalanceAsLendingConnector : lendingConnector;
    }
}
