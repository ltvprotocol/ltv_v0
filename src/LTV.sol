// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./borrowVault/PreviewDeposit.sol";
import "./borrowVault/PreviewWithdraw.sol";
import "./borrowVault/PreviewMint.sol";
import "./borrowVault/PreviewRedeem.sol";
import "./borrowVault/Deposit.sol";
import "./borrowVault/Withdraw.sol";
import './borrowVault/Redeem.sol';
import './borrowVault/Mint.sol';
import './utils/Ownable.sol';
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


abstract contract LTV is PreviewWithdraw, PreviewDeposit, PreviewMint, PreviewRedeem, PreviewWithdrawCollateral, PreviewDepositCollateral, PreviewMintCollateral, PreviewRedeemCollateral, Auction, Mint, MintCollateral, Deposit, DepositCollateral, Withdraw, WithdrawCollateral, Redeem, RedeemCollateral, ConvertToAssets, ConvertToShares, Ownable {
    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);
    event TargetLTVChanged(uint128 oldValue, uint128 newValue);

    constructor(address initialOwner) ERC20("LTV", "LTV", 18) Ownable(initialOwner) {
        //
    }

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
}
