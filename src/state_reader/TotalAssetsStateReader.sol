// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./GetLendingConnectorReader.sol";
import "src/interfaces/ILendingConnector.sol";
import "src/structs/state/vault/TotalAssetsState.sol";

contract TotalAssetsStateReader is GetLendingConnectorReader {
    function totalAssetsState(bool isDeposit) internal view returns (TotalAssetsState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        return TotalAssetsState({
            // default behavior - don't overestimate our assets
            realCollateralAssets: _lendingConnector.getRealCollateralAssets(isDeposit),
            realBorrowAssets: _lendingConnector.getRealBorrowAssets(isDeposit),
            commonTotalAssetsState: CommonTotalAssetsState({
                futureBorrowAssets: futureBorrowAssets,
                futureCollateralAssets: futureCollateralAssets,
                futureRewardBorrowAssets: futureRewardBorrowAssets,
                futureRewardCollateralAssets: futureRewardCollateralAssets,
                borrowPrice: oracleConnector.getPriceBorrowOracle(),
                collateralPrice: oracleConnector.getPriceCollateralOracle()
            })
        });
    }
}
