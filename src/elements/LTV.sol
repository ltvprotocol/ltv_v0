// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../facades/reads/AuctionRead.sol';
import '../facades/writes/AuctionWrite.sol';
import '../public/erc20/TotalSupply.sol';
import '../facades/writes/ERC20Write.sol';
import '../facades/reads/LowLevelRebalanceRead.sol';
import '../facades/writes/LowLevelRebalanceWrite.sol';
import '../facades/reads/BorrowVaultRead.sol';
import '../facades/writes/BorrowVaultWrite.sol';
import '../facades/reads/CollateralVaultRead.sol';
import '../facades/writes/CollateralVaultWrite.sol';
import '../facades/writes/AdministrationWrite.sol';
import '../utils/UpgradeableOwnableWithGuardianAndGovernor.sol';
import '../facades/reads/AdministrationRead.sol';
contract LTV is
    AuctionRead,
    AuctionWrite,
    TotalSupply,
    ERC20Write,
    LowLevelRebalanceRead,
    LowLevelRebalanceWrite,
    BorrowVaultRead,
    BorrowVaultWrite,
    CollateralVaultRead,
    CollateralVaultWrite,
    AdministrationWrite,
    AdministrationRead
{}
