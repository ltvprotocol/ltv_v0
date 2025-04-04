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
import './Auction.sol';
import './LowLevel.sol';
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
    LowLevel,
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
    
    function initialize(StateInitData memory stateInitData, address initialOwner, string memory _name, string memory _symbol) initializer public isFunctionAllowed {
        __State_init(stateInitData);
        __ERC20_init(_name, _symbol, 18);
        __Ownable_init(initialOwner);
    }

    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);
    event TargetLTVChanged(uint128 oldValue, uint128 newValue);

    function setTargetLTV(uint128 value) external onlyOwner {
        uint128 oldValue = targetLTV;
        targetLTV = value;
        emit TargetLTVChanged(oldValue, targetLTV);
    }

    function setMaxSafeLTV(uint128 value) external onlyOwner {
        uint128 oldValue = maxSafeLTV;
        maxSafeLTV = value;
        emit MaxSafeLTVChanged(oldValue, value);
    }

    function setMinProfitLTV(uint128 value) external onlyOwner {
        uint128 oldValue = minProfitLTV;
        minProfitLTV = value;
        emit MinProfitLTVChanged(oldValue, value);
    }

    function setLendingConnector(ILendingConnector _lendingConnector) external onlyOwner {
        lendingConnector = _lendingConnector;
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external onlyOwner {
        maxTotalAssetsInUnderlying = _maxTotalAssetsInUnderlying;
    }

    function setMissingSlots(ILendingConnector _lendingConnector, IOracleConnector _oracleConnector) external onlyOwner {
        lendingConnector = _lendingConnector;
        oracleConnector = _oracleConnector;
        lastSeenTokenPrice = totalAssets().mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, totalSupply());
        maxGrowthFee = 10 ** 18 / 5;
        maxTotalAssetsInUnderlying = type(uint128).max;
    }

    // batch can be removed to save ~250 bytes of contract size
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyOwner {
        for (uint256 i = 0; i < signatures.length; i++) {
            _isFunctionDisabled[signatures[i]] = isDisabled;
        }
    }

    function setSlippageProvider(ISlippageProvider _slippageProvider) external onlyOwner {
        slippageProvider = _slippageProvider;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function borrow(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector).delegatecall(abi.encodeCall(lendingConnector.borrow, (assets)));
        require(isSuccess);
    }

    function repay(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector).delegatecall(abi.encodeCall(lendingConnector.repay, (assets)));
        require(isSuccess);
    }

    function supply(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector).delegatecall(abi.encodeCall(lendingConnector.supply, (assets)));
        require(isSuccess);
    }

    function withdraw(uint256 assets) internal override {
        (bool isSuccess, ) = address(lendingConnector).delegatecall(abi.encodeCall(lendingConnector.withdraw, (assets)));
        require(isSuccess);
    }
}
