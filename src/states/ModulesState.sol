// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../interfaces/reads/IERC20Read.sol";
import "../interfaces/reads/IAuctionRead.sol";

abstract contract ModulesState {
    address public borrowVaultsRead;
    address public collateralVaultsRead;
    IERC20Read public erc20Read;
    address public lowLevelRebalancerRead;
    IAuctionRead public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    address public erc20Write;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
}
