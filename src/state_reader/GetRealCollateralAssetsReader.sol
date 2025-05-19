// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/states/LTVState.sol';
import './GetLendingConnectorReader.sol';

contract GetRealCollateralAssetsReader is GetLendingConnectorReader {
    function getRealCollateralAssets() external view returns (uint256) {
        return getLendingConnector().getRealCollateralAssets();
    }
} 