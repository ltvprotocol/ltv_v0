// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";

contract GetRealCollateralAssetsReader is GetLendingConnectorReader {
    function getRealCollateralAssets(bool isDeposit) external view returns (uint256) {
        return getLendingConnector().getRealCollateralAssets(isDeposit, connectorGetterData);
    }
}
