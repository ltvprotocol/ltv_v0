// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {CommonTotalAssetsState} from "./CommonTotalAssetsState.sol";

/**
 * @title TotalAssetsState
 * @notice This struct needed for total assets calculations
 */
struct TotalAssetsState {
    uint256 realCollateralAssets;
    uint256 realBorrowAssets;
    CommonTotalAssetsState commonTotalAssetsState;
}
