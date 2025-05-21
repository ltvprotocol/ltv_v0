// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './GetLendingConnectorReader.sol';
import 'src/interfaces/ILendingConnector.sol';
import 'src/structs/state/vault/TotalAssetsState.sol';

contract TotalAssetsStateReader is GetLendingConnectorReader {
    function totalAssetsState() internal view returns (TotalAssetsState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        return
            TotalAssetsState({
                realCollateralAssets: _lendingConnector.getRealCollateralAssets(),
                realBorrowAssets: _lendingConnector.getRealBorrowAssets(),
                futureBorrowAssets: futureBorrowAssets,
                futureCollateralAssets: futureCollateralAssets,
                futureRewardBorrowAssets: futureRewardBorrowAssets,
                futureRewardCollateralAssets: futureRewardCollateralAssets,
                borrowPrice: oracleConnector.getPriceBorrowOracle(),
                collateralPrice: oracleConnector.getPriceCollateralOracle()
            });
    }
} 