// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './borrowVault/PreviewDeposit.sol';
import './borrowVault/PreviewWithdraw.sol';
import './borrowVault/PreviewMint.sol';
import './borrowVault/PreviewRedeem.sol';
import './borrowVault/Deposit.sol';
import './borrowVault/Withdraw.sol';
import './borrowVault/Redeem.sol';
import './borrowVault/Mint.sol';
import './borrowVault/ConvertToAssets.sol';
import './borrowVault/ConvertToShares.sol';
import './collateralVault/DepositCollateral.sol';
import './collateralVault/WithdrawCollateral.sol';
import './collateralVault/RedeemCollateral.sol';
import './collateralVault/MintCollateral.sol';
import './collateralVault/PreviewDepositCollateral.sol';
import './collateralVault/PreviewWithdrawCollateral.sol';
import './collateralVault/PreviewMintCollateral.sol';
import './collateralVault/PreviewRedeemCollateral.sol';
import './collateralVault/ConvertToAssetsCollateral.sol';
import './collateralVault/ConvertToSharesCollateral.sol';
import './Auction.sol';
import './LowLevelRebalance.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract LTV is
    PreviewWithdraw,
    PreviewDeposit,
    PreviewMint,
    PreviewRedeem,
    PreviewWithdrawCollateral,
    PreviewDepositCollateral,
    PreviewMintCollateral,
    PreviewRedeemCollateral,
    LowLevelRebalance,
    Auction,
    Mint,
    MintCollateral,
    Deposit,
    DepositCollateral,
    Withdraw,
    WithdrawCollateral,
    Redeem,
    RedeemCollateral,
    ConvertToAssets,
    ConvertToShares
{
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function initialize(
        StateInitData memory stateInitData,
        address initialOwner,
        string memory _name,
        string memory _symbol
    ) public initializer isFunctionAllowed {
        __State_init(stateInitData);
        __ERC20_init(_name, _symbol, 18);
        __Ownable_init(initialOwner);
    }

    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);
    event TargetLTVChanged(uint128 oldValue, uint128 newValue);

    error InvalidLTVSet(uint128 targetLTV, uint128 maxSafeLTV, uint128 minProfitLTV);
    error ImpossibleToCoverDeleverage(uint256 realBorrowAssets, uint256 providedAssets);
    error InvalidMaxDeleverageFee(uint256 deleverageFee);
    error ExceedsMaxDeleverageFee(uint256 deleverageFee, uint256 maxDeleverageFee);
    event WhitelistRegistryUpdated(address oldValue, address newValue);

    function setTargetLTV(uint128 value) external onlyOwnerOrGovernor {
        require(value <= maxSafeLTV && value >= minProfitLTV, InvalidLTVSet(value, maxSafeLTV, minProfitLTV));
        uint128 oldValue = targetLTV;
        targetLTV = value;
        emit TargetLTVChanged(oldValue, targetLTV);
    }

    function setMaxSafeLTV(uint128 value) external onlyOwnerOrGovernor {
        require(value >= targetLTV, InvalidLTVSet(targetLTV, value, minProfitLTV));
        uint128 oldValue = maxSafeLTV;
        maxSafeLTV = value;
        emit MaxSafeLTVChanged(oldValue, value);
    }

    function setMinProfitLTV(uint128 value) external onlyOwnerOrGovernor {
        require(value <= targetLTV, InvalidLTVSet(targetLTV, maxSafeLTV, value));
        uint128 oldValue = minProfitLTV;
        minProfitLTV = value;
        emit MinProfitLTVChanged(oldValue, value);
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external onlyOwnerOrGovernor {
        maxTotalAssetsInUnderlying = _maxTotalAssetsInUnderlying;
    }

    // batch can be removed to save ~250 bytes of contract size
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyOwnerOrGovernor {
        for (uint256 i = 0; i < signatures.length; i++) {
            _isFunctionDisabled[signatures[i]] = isDisabled;
        }
    }

    function setLendingConnector(ILendingConnector __lendingConnector) external onlyOwner {
        _lendingConnector = __lendingConnector;
    }

    function setSlippageProvider(ISlippageProvider _slippageProvider) external onlyOwner {
        slippageProvider = _slippageProvider;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function setIsWhitelistActivated(bool activate) external onlyOwner {
        isWhitelistActivated = activate;
    }

    function setWhitelistRegistry(IWhitelistRegistry value) external onlyOwner {
        address oldAddress = address(whitelistRegistry);
        whitelistRegistry = value;
        emit WhitelistRegistryUpdated(oldAddress, address(value));
    }

    function setMaxDeleverageFee(uint256 value) external onlyOwner {
        require(value < 10**18, InvalidMaxDeleverageFee(value));
        maxDeleverageFee = value;
    }

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint256 deleverageFee) external onlyOwner {
        require(deleverageFee <= maxDeleverageFee, ExceedsMaxDeleverageFee(deleverageFee, maxDeleverageFee));
        futureBorrowAssets = 0;
        futureCollateralAssets = 0;
        futureRewardBorrowAssets = 0;
        futureRewardCollateralAssets = 0;
        startAuction = 0;

        uint256 realBorrowAssets = getRealBorrowAssets();

        require(closeAmountBorrow >= realBorrowAssets, ImpossibleToCoverDeleverage(realBorrowAssets, closeAmountBorrow));
        
        uint256 collateralToTransfer = realBorrowAssets.mulDivUp(10 ** 18 + deleverageFee, 10 ** 18).mulDivDown(
            getPriceBorrowOracle(),
            getPriceCollateralOracle()
        );

        borrowToken.transferFrom(msg.sender, address(this), realBorrowAssets);
        repay(realBorrowAssets);
        withdraw(getRealCollateralAssets());
        collateralToken.transfer(msg.sender, collateralToTransfer);
        isVaultDeleveraged = true;
    }

    function borrow(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        require(isSuccess);
    }

    function repay(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        require(isSuccess);
    }

    function supply(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        require(isSuccess);
    }

    function withdraw(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        require(isSuccess);
    }
}
