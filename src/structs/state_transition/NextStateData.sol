// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./NextState.sol";

struct NextStateData {
    NextState nextState;
    uint256 borrowPrice;
    uint256 collateralPrice;
} 