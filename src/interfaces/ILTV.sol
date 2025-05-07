// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ILTV {
    function _isFunctionDisabled(bytes4) external view returns (bool);

    function _previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        uint256 supply
    )
        external
        view
        returns (
            int256,
            int256,
            int256
        );

    function _totalAssetsCollateral(bool isDeposit)
        external
        view
        returns (uint256);

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled)
        external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function baseTotalSupply() external view returns (uint256);

    function borrowToken() external view returns (address);

    function collateralToken() external view returns (address);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function currentLendingConnector() external view returns (address);

    function decimals() external view returns (uint8);

    function deleverageAndWithdraw(
        uint256 closeAmountBorrow,
        uint256 deleverageFee
    ) external;

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256);

    function depositCollateral(uint256 collateralAssets, address receiver)
        external
        returns (uint256);

    function executeAuctionBorrow(int256 deltaUserBorrowAssets)
        external
        returns (int256);

    function executeAuctionCollateral(int256 deltaUserCollateralAssets)
        external
        returns (int256);

    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets)
        external
        returns (int256, int256);

    function executeLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint
    ) external returns (int256, int256);

    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets)
        external
        returns (int256, int256);

    function executeLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint
    ) external returns (int256, int256);

    function executeLowLevelRebalanceShares(int256 deltaShares)
        external
        returns (int256, int256);

    function feeCollector() external view returns (address);

    function futureBorrowAssets() external view returns (int256);

    function futureCollateralAssets() external view returns (int256);

    function futureRewardBorrowAssets() external view returns (int256);

    function futureRewardCollateralAssets() external view returns (int256);

    function getPriceBorrowOracle() external view returns (uint256);

    function getPriceCollateralOracle() external view returns (uint256);

    function getRealBorrowAssets() external view returns (uint256);

    function getRealCollateralAssets() external view returns (uint256);

    function initialize(
        State.StateInitData memory stateInitData,
        address initialOwner,
        string memory _name,
        string memory _symbol
    ) external;

    function isDepositDisabled() external view returns (bool);

    function isWhitelistActivated() external view returns (bool);

    function isWithdrawDisabled() external view returns (bool);

    function maxDeleverageFee() external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxDepositCollateral(address) external view returns (uint256);

    function maxLowLevelRebalanceBorrow() external view returns (int256);

    function maxLowLevelRebalanceCollateral() external view returns (int256);

    function maxLowLevelRebalanceShares() external view returns (int256);

    function maxMint(address) external view returns (uint256);

    function maxMintCollateral(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxRedeemCollateral(address owner) external view returns (uint256);

    function maxSafeLTV() external view returns (uint128);

    function maxTotalAssetsInUnderlying() external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxWithdrawCollateral(address owner)
        external
        view
        returns (uint256);

    function minProfitLTV() external view returns (uint128);

    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets);

    function mintCollateral(uint256 shares, address receiver)
        external
        returns (uint256 collateralAssets);

    function name() external view returns (string memory);

    function oracleConnector() external view returns (address);

    function owner() external view returns (address);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewDepositCollateral(uint256 collateralAssets)
        external
        view
        returns (uint256 shares);

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets)
        external
        view
        returns (int256);

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets)
        external
        view
        returns (int256);

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets)
        external
        view
        returns (int256, int256);

    function previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint
    )
        external
        view
        returns (
            int256,
            int256
        );

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets)
        external
        view
        returns (int256, int256);

    function previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint
    )
        external
        view
        returns (
            int256,
            int256
        );

    function previewLowLevelRebalanceShares(int256 deltaShares)
        external
        view
        returns (int256, int256);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function previewMintCollateral(uint256 shares)
        external
        view
        returns (uint256 collateralAssets);

    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256 assets);

    function previewRedeemCollateral(uint256 shares)
        external
        view
        returns (uint256 assets);

    function previewWithdraw(uint256 assets)
        external
        view
        returns (uint256 shares);

    function previewWithdrawCollateral(uint256 assets)
        external
        view
        returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function redeemCollateral(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 collateralAssets);

    function renounceOwnership() external;

    function setFeeCollector(address _feeCollector) external;

    function setIsDepositDisabled(bool value) external;

    function setIsWhitelistActivated(bool activate) external;

    function setIsWithdrawDisabled(bool value) external;

    function setLendingConnector(address _lendingConnector) external;

    function setMaxDeleverageFee(uint256 value) external;

    function setMaxGrowthFee(uint256 _maxGrowthFee) external;

    function setMaxSafeLTV(uint128 value) external;

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying)
        external;

    function setMinProfitLTV(uint128 value) external;

    function setOracleConnector(address _oracleConnector) external;

    function setSlippageProvider(address _slippageProvider) external;

    function setTargetLTV(uint128 value) external;

    function setWhitelistRegistry(address value) external;

    function slippageProvider() external view returns (address);

    function startAuction() external view returns (uint256);

    function symbol() external view returns (string memory);

    function targetLTV() external view returns (uint128);

    function totalAssets() external view returns (uint256);

    function totalAssetsCollateral() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function vaultBalanceAsLendingConnector() external view returns (address);

    function whitelistRegistry() external view returns (address);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function withdrawCollateral(
        uint256 collateralAssets,
        address receiver,
        address owner
    ) external returns (uint256);

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function deleverageWithdrawer() external view returns (address);

    function updateOwner(address newOwner) external;

    function updateGuardian(address newGuardian) external;

    function updateGovernor(address newGovernor) external;

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external;

    function lendingConnector() external view returns (address);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event AuctionExecuted(
        address executor,
        int256 deltaRealCollateralAssets,
        int256 deltaRealBorrowAssets
    );
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event DepositCollateral(
        address indexed sender,
        address indexed owner,
        uint256 collateralAssets,
        uint256 shares
    );
    event Initialized(uint64 version);
    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event StateUpdated(
        int256 oldFutureBorrowAssets,
        int256 oldFutureCollateralAssets,
        int256 oldFutureRewardBorrowAssets,
        int256 oldFutureRewardCollateralAssets,
        uint256 oldStartAuction,
        int256 newFutureBorrowAssets,
        int256 newFutureCollateralAssets,
        int256 newFutureRewardBorrowAssets,
        int256 newFutureRewardCollateralAssets,
        uint256 newStartAuction
    );
    event TargetLTVChanged(uint128 oldValue, uint128 newValue);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event WhitelistRegistryUpdated(address oldValue, address newValue);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event WithdrawCollateral(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 collateralAssets,
        uint256 shares
    );
    error DepositIsDisabled();
    error ExceedsLowLevelRebalanceMaxDeltaBorrow(
        int256 deltaBorrow,
        int256 max
    );
    error ExceedsLowLevelRebalanceMaxDeltaCollareral(
        int256 deltaCollateral,
        int256 max
    );
    error ExceedsLowLevelRebalanceMaxDeltaShares(
        int256 deltaShares,
        int256 max
    );
    error ExceedsMaxDeleverageFee(
        uint256 deleverageFee,
        uint256 maxDeleverageFee
    );
    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);
    error ExceedsMaxDepositCollateral(
        address receiver,
        uint256 collateralAssets,
        uint256 max
    );
    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);
    error ExceedsMaxMintCollateral(
        address receiver,
        uint256 shares,
        uint256 max
    );
    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);
    error ExceedsMaxRedeemCollateral(
        address owner,
        uint256 shares,
        uint256 max
    );
    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);
    error ExceedsMaxWithdrawCollateral(
        address owner,
        uint256 collateralAssets,
        uint256 max
    );
    error FunctionStopped(bytes4 functionSignature);
    error ImpossibleToCoverDeleverage(
        uint256 realBorrowAssets,
        uint256 providedAssets
    );
    error InvalidInitialization();
    error InvalidLTVSet(
        uint128 targetLTV,
        uint128 maxSafeLTV,
        uint128 minProfitLTV
    );
    error InvalidMaxDeleverageFee(uint256 deleverageFee);
    error NotInitializing();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error ReceiverNotWhitelisted(address receiver);
    error ReentrancyGuardReentrantCall();
    error VaultAlreadyDeleveraged();
    error WithdrawIsDisabled();
}

interface State {
    struct StateInitData {
        address collateralToken;
        address borrowToken;
        address feeCollector;
        uint128 maxSafeLTV;
        uint128 minProfitLTV;
        uint128 targetLTV;
        address lendingConnector;
        address oracleConnector;
        uint256 maxGrowthFee;
        uint256 maxTotalAssetsInUnderlying;
        address slippageProvider;
        uint256 maxDeleverageFee;
        address vaultBalanceAsLendingConnector;
    }
}