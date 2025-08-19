// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {CommonTotalAssetsState} from "src/structs/state/vault/CommonTotalAssetsState.sol";
import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";

contract TotalAssetsStateReader is GetLendingConnectorReader {
    function totalAssetsState(bool isDeposit) internal view returns (TotalAssetsState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        bytes memory _oracleConnectorGetterData = oracleConnectorGetterData;
        return TotalAssetsState({
            // default behavior - don't overestimate our assets
            realCollateralAssets: _lendingConnector.getRealCollateralAssets(isDeposit, _lendingConnectorGetterData),
            realBorrowAssets: _lendingConnector.getRealBorrowAssets(isDeposit, _lendingConnectorGetterData),
            commonTotalAssetsState: CommonTotalAssetsState({
                futureBorrowAssets: futureBorrowAssets,
                futureCollateralAssets: futureCollateralAssets,
                futureRewardBorrowAssets: futureRewardBorrowAssets,
                futureRewardCollateralAssets: futureRewardCollateralAssets,
                borrowPrice: oracleConnector.getPriceBorrowOracle(_oracleConnectorGetterData),
                collateralPrice: oracleConnector.getPriceCollateralOracle(_oracleConnectorGetterData)
            })
        });
    }
}
