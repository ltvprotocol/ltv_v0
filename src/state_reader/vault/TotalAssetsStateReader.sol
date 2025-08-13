// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../GetLendingConnectorReader.sol";
import "src/interfaces/ILendingConnector.sol";
import "src/structs/state/vault/TotalAssetsState.sol";

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
