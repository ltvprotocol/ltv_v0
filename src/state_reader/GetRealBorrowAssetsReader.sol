// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/states/LTVState.sol";
import "./GetLendingConnectorReader.sol";

contract GetRealBorrowAssetsReader is GetLendingConnectorReader {
    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        return getLendingConnector().getRealBorrowAssets(isDeposit, connectorGetterData);
    }
}
