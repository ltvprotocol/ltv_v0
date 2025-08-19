// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";

contract GetRealBorrowAssetsReader is GetLendingConnectorReader {
    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        return getLendingConnector().getRealBorrowAssets(isDeposit, connectorGetterData);
    }
}
