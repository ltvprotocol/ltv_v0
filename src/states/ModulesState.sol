// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../interfaces/reads/IERC20Read.sol";
import "../interfaces/reads/IAuctionRead.sol";
import "../interfaces/reads/ILowLevelRebalanceRead.sol";
import "../interfaces/reads/IBorrowVaultRead.sol";

abstract contract ModulesState {
    IBorrowVaultRead public borrowVaultsRead;
    address public collateralVaultsRead;
    IERC20Read public erc20Read;
    ILowLevelRebalanceRead public lowLevelRebalancerRead;
    IAuctionRead public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    address public erc20Write;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
}
