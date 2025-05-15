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
    ILowLevelRebalanceRead lowLevelRebalancerRead;
    IAuctionRead auctionRead;
    IAdministration administration;
    IERC20Read erc20;
    address borrowVaultsWrite;
    address collateralVaultsWrite;
    address lowLevelRebalancerWrite;
    address auctionWrite;
}

contract ModulesProvider is IModules {
    constructor(ModulesState memory state) {
        borrowVaultsRead = state.borrowVaultsRead;
        collateralVaultsRead = state.collateralVaultsRead;
        lowLevelRebalancerRead = state.lowLevelRebalancerRead;
        auctionRead = state.auctionRead;

        borrowVaultsWrite = state.borrowVaultsWrite;
        collateralVaultsWrite = state.collateralVaultsWrite;
        erc20 = state.erc20;
        lowLevelRebalancerWrite = state.lowLevelRebalancerWrite;
        auctionWrite = state.auctionWrite;
        administration = state.administration;
    }

    IBorrowVaultRead public borrowVaultsRead;
    ICollateralVaultRead public collateralVaultsRead;
    ILowLevelRebalanceRead public lowLevelRebalancerRead;
    IAuctionRead public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    IERC20Read public erc20;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
    IAdministration public administration;
}
