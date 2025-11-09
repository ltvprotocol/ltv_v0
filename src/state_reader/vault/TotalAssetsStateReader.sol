// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsState} from "../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {CommonTotalAssetsState} from "../../structs/state/vault/total_assets/CommonTotalAssetsState.sol";
import {GetRealCollateralAndRealBorrowAssetsReader} from "../common/GetRealCollateralAndRealBorrowAssetsReader.sol";

/**
 * @title TotalAssetsStateReader
 * @notice contract contains functionality to retrieve total assets згку state
 * needed for total assets calculation
 */
contract TotalAssetsStateReader is GetRealCollateralAndRealBorrowAssetsReader {
    /**
     * @dev function to retrieve total assets state for total assets calculation
     */
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
                collateralPrice: oracleConnector.getPriceCollateralOracle(_oracleConnectorGetterData),
                borrowTokenDecimals: borrowTokenDecimals,
                collateralTokenDecimals: collateralTokenDecimals
            })
        });
    }
}
