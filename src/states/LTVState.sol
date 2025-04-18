// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../interfaces/ILendingConnector.sol';
import '../interfaces/IOracleConnector.sol';
import '../interfaces/IWhitelistRegistry.sol';
import '../interfaces/ISlippageProvider.sol';
import '../interfaces/IModules.sol';
import 'forge-std/interfaces/IERC20.sol';

abstract contract LTVState {
    // ------------------------------------------------

    address public feeCollector;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;
    uint256 public startAuction;

    // ERC 20 state
    uint256 public baseTotalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint128 public maxSafeLTV;
    uint128 public minProfitLTV;
    uint128 public targetLTV;
    
    // TODO: why it's internal?
    ILendingConnector internal lendingConnector;
    bool public isVaultDeleveraged;
    IOracleConnector public oracleConnector;

    // TODO: why it's internal?
    uint256 internal lastSeenTokenPrice;
    // TODO: why it's internal?
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;
    ISlippageProvider public slippageProvider;
    bool public isDepositDisabled;
    bool public isWithdrawDisabled;
    IWhitelistRegistry public whitelistRegistry;
    bool public isWhitelistActivated;

    uint256 public maxDeleverageFee;
    ILendingConnector public vaultBalanceAsLendingConnector;

    IModules public modules;
}