// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {CommonTotalAssetsState} from "src/structs/state/vault/CommonTotalAssetsState.sol";
import {GetRealCollateralAndRealBorrowAssetsReader} from "../common/GetRealCollateralAndRealBorrowAssetsReader.sol";

contract TotalAssetsStateReader is GetRealCollateralAndRealBorrowAssetsReader {
    function totalAssetsState(bool isDeposit) internal view returns (TotalAssetsState memory) {
        (uint256 realCollateralAssets, uint256 realBorrowAssets) = getRealCollateralAndRealBorrowAssets(isDeposit);
        bytes memory _oracleConnectorGetterData = oracleConnectorGetterData;
        return TotalAssetsState({
            // default behavior - don't overestimate our assets
            realCollateralAssets: realCollateralAssets,
            realBorrowAssets: realBorrowAssets,
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
