// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/errors/IAdministrationErrors.sol";
import "src/errors/IVaultErrors.sol";
import "src/errors/ILowLevelRebalanceErrors.sol";
import "src/errors/IAuctionErrors.sol";

import "src/events/IAdministrationEvents.sol";
import "src/events/IAuctionEvent.sol";
import "src/events/IERC4626Events.sol";
import "src/events/IERC20Events.sol";
import "src/events/ILowLevelRebalanceEvent.sol";
import "src/events/IStateUpdateEvent.sol";
import "src/interfaces/IModules.sol";

interface ILTV is
    IAdministrationErrors,
    IVaultErrors,
    ILowLevelRebalanceErrors,
    IAuctionErrors,
    IAdministrationEvents,
    ILowLevelRebalanceEvent,
    IAuctionEvent,
    IERC4626Events,
    IERC20Events,
    IStateUpdateEvent
{
    function _isFunctionDisabled(bytes4) external view returns (bool);

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function baseTotalSupply() external view returns (uint256);

    function borrowToken() external view returns (address);

    function collateralToken() external view returns (address);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function getLendingConnector() external view returns (address);

    function decimals() external view returns (uint8);

    function maxGrowthFeeDividend() external view returns (uint16);

    function maxGrowthFeeDivider() external view returns (uint16);

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external;

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function depositCollateral(uint256 collateralAssets, address receiver) external returns (uint256);

    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256);

    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256);

    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external returns (int256, int256);

    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint)
        external
        returns (int256, int256);

    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external returns (int256, int256);

    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint)
        external
        returns (int256, int256);

    function executeLowLevelRebalanceShares(int256 deltaShares) external returns (int256, int256);

    function feeCollector() external view returns (address);

    function futureBorrowAssets() external view returns (int256);

    function futureCollateralAssets() external view returns (int256);

    function futureRewardBorrowAssets() external view returns (int256);

    function futureRewardCollateralAssets() external view returns (int256);

    function getRealBorrowAssets(bool isDeposit) external view returns (uint256);

    function getRealCollateralAssets(bool isDeposit) external view returns (uint256);

    function initialize(StateInitData memory stateInitData, IModules modules) external;

    function isDepositDisabled() external view returns (bool);

    function isWhitelistActivated() external view returns (bool);

    function isWithdrawDisabled() external view returns (bool);

    function maxDeleverageFeeDividend() external view returns (uint16);

    function maxDeleverageFeeDivider() external view returns (uint16);

    function maxDeposit(address) external view returns (uint256);

    function maxDepositCollateral(address) external view returns (uint256);

    function maxLowLevelRebalanceBorrow() external view returns (int256);

    function maxLowLevelRebalanceCollateral() external view returns (int256);

    function maxLowLevelRebalanceShares() external view returns (int256);

    function maxMint(address) external view returns (uint256);

    function maxMintCollateral(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxRedeemCollateral(address owner) external view returns (uint256);

    function maxSafeLTVDividend() external view returns (uint16);

    function maxSafeLTVDivider() external view returns (uint16);

    function maxTotalAssetsInUnderlying() external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxWithdrawCollateral(address owner) external view returns (uint256);

    function minProfitLTVDividend() external view returns (uint16);

    function minProfitLTVDivider() external view returns (uint16);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function mintCollateral(uint256 shares, address receiver) external returns (uint256 collateralAssets);

    function name() external view returns (string memory);

    function oracleConnector() external view returns (address);

    function owner() external view returns (address);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewDepositCollateral(uint256 collateralAssets) external view returns (uint256 shares);

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256);

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256);

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256);

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256);

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256);

    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint)
        external
        view
        returns (int256, int256);

    function previewLowLevelRebalanceShares(int256 deltaShares) external view returns (int256, int256);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function previewMintCollateral(uint256 shares) external view returns (uint256 collateralAssets);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function previewRedeemCollateral(uint256 shares) external view returns (uint256 assets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function previewWithdrawCollateral(uint256 assets) external view returns (uint256 shares);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function redeemCollateral(uint256 shares, address receiver, address owner)
        external
        returns (uint256 collateralAssets);

    function renounceOwnership() external;

    function setFeeCollector(address _feeCollector) external;

    function setIsDepositDisabled(bool value) external;

    function setIsWhitelistActivated(bool activate) external;

    function setIsWithdrawDisabled(bool value) external;

    function setLendingConnector(address _lendingConnector) external;

    function setMaxDeleverageFee(uint16 dividend, uint16 divider) external;

    function setMaxGrowthFee(uint16 dividend, uint16 divider) external;

    function setMaxSafeLTV(uint16 dividend, uint16 divider) external;

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external;

    function setMinProfitLTV(uint16 dividend, uint16 divider) external;

    function setOracleConnector(address _oracleConnector) external;

    function setSlippageProvider(address _slippageProvider) external;

    function setTargetLTV(uint16 dividend, uint16 divider) external;

    function setWhitelistRegistry(address value) external;

    function setModules(IModules _modules) external;

    function slippageProvider() external view returns (address);

    function startAuction() external view returns (uint56);

    function auctionDuration() external view returns (uint24);

    function symbol() external view returns (string memory);

    function targetLTVDividend() external view returns (uint16);

    function targetLTVDivider() external view returns (uint16);

    function totalAssets() external view returns (uint256);

    function totalAssets(bool isDeposit) external view returns (uint256);

    function totalAssetsCollateral() external view returns (uint256);

    function totalAssetsCollateral(bool isDeposit) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function vaultBalanceAsLendingConnector() external view returns (address);

    function whitelistRegistry() external view returns (address);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function withdrawCollateral(uint256 collateralAssets, address receiver, address owner) external returns (uint256);

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function emergencyDeleverager() external view returns (address);

    function transferOwnership(address newOwner) external;

    function updateGuardian(address newGuardian) external;

    function updateGovernor(address newGovernor) external;

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external;

    function lendingConnector() external view returns (address);

    function lastSeenTokenPrice() external view returns (uint256);

    event Initialized(uint64 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error InvalidInitialization();
    error NotInitializing();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error ReentrancyGuardReentrantCall();
}
