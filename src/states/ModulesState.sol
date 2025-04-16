// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract ModulesState {
    address public borrowVaultsRead;
    address public collateralVaultsRead;
    address public erc20Read;
    address public lowLevelRebalancerRead;
    address public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    address public erc20Write;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
}
