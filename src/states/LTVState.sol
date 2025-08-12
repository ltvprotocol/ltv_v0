// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../interfaces/ILendingConnector.sol";
import "../interfaces/IOracleConnector.sol";
import "../interfaces/IWhitelistRegistry.sol";
import "../interfaces/ISlippageProvider.sol";
import "../interfaces/IModules.sol";
import "forge-std/interfaces/IERC20.sol";
import "../structs/state/vault/TotalAssetsState.sol";
import "../structs/state/MaxGrowthFeeState.sol";
import "../structs/state/vault/PreviewVaultState.sol";
import "../structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import "../structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import "../structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import "../structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import "../structs/state/AuctionState.sol";
import "../structs/state/low_level/PreviewLowLevelRebalanceState.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";
import "../structs/state/low_level/ExecuteLowLevelRebalanceState.sol";

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

    ILendingConnector public lendingConnector;
    bool public isVaultDeleveraged;
    IOracleConnector public oracleConnector;

    uint256 public lastSeenTokenPrice;

    uint256 public maxGrowthFee;

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

    address public governor;
    address public guardian;
    address public emergencyDeleverager;

    bytes public lendingConnectorGetterData;
    bytes public oracleConnectorGetterData;

}