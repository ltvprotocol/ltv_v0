// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../interfaces/reads/IERC20Read.sol';
import '../interfaces/reads/IAuctionRead.sol';
import '../interfaces/reads/ILowLevelRebalanceRead.sol';
import '../interfaces/reads/IBorrowVaultRead.sol';
import '../interfaces/reads/ICollateralVaultRead.sol';
import '../interfaces/IModules.sol';
struct ModulesState {
    IBorrowVaultRead borrowVaultsRead;
    ICollateralVaultRead collateralVaultsRead;
    IERC20Read erc20Read;
    ILowLevelRebalanceRead lowLevelRebalancerRead;
    IAuctionRead auctionRead;
    address borrowVaultsWrite;
    address collateralVaultsWrite;
    address erc20Write;
    address lowLevelRebalancerWrite;
    address auctionWrite;
    address administrationWrite;
}

contract ModulesProvider is IModules {
    constructor(ModulesState memory state) {
        borrowVaultsRead = state.borrowVaultsRead;
        collateralVaultsRead = state.collateralVaultsRead;
        erc20Read = state.erc20Read;
        lowLevelRebalancerRead = state.lowLevelRebalancerRead;
        auctionRead = state.auctionRead;

        borrowVaultsWrite = state.borrowVaultsWrite;
        collateralVaultsWrite = state.collateralVaultsWrite;
        erc20Write = state.erc20Write;
        lowLevelRebalancerWrite = state.lowLevelRebalancerWrite;
        auctionWrite = state.auctionWrite;
        administrationWrite = state.administrationWrite;
    }

    IBorrowVaultRead public borrowVaultsRead;
    ICollateralVaultRead public collateralVaultsRead;
    IERC20Read public erc20Read;
    ILowLevelRebalanceRead public lowLevelRebalancerRead;
    IAuctionRead public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    address public erc20Write;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
    address public administrationWrite;
}
