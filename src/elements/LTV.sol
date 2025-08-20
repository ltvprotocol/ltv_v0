// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionRead} from "src/facades/reads/AuctionRead.sol";
import {AuctionWrite} from "src/facades/writes/AuctionWrite.sol";
import {ERC20Read} from "src/facades/reads/ERC20Read.sol";
import {ERC20Write} from "src/facades/writes/ERC20Write.sol";
import {LowLevelRebalanceRead} from "src/facades/reads/LowLevelRebalanceRead.sol";
import {LowLevelRebalanceWrite} from "src/facades/writes/LowLevelRebalanceWrite.sol";
import {BorrowVaultRead} from "src/facades/reads/BorrowVaultRead.sol";
import {BorrowVaultWrite} from "src/facades/writes/BorrowVaultWrite.sol";
import {CollateralVaultRead} from "src/facades/reads/CollateralVaultRead.sol";
import {CollateralVaultWrite} from "src/facades/writes/CollateralVaultWrite.sol";
import {AdministrationWrite} from "src/facades/writes/AdministrationWrite.sol";
import {InitializeWrite} from "src/facades/writes/InitializeWrite.sol";

contract LTV is
    AuctionRead,
    AuctionWrite,
    ERC20Read,
    ERC20Write,
    LowLevelRebalanceRead,
    LowLevelRebalanceWrite,
    BorrowVaultRead,
    BorrowVaultWrite,
    CollateralVaultRead,
    CollateralVaultWrite,
    AdministrationWrite,
    InitializeWrite
{}
