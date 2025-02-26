// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./borrowVault/PreviewDeposit.sol";
import "./borrowVault/PreviewWithdraw.sol";
import "./borrowVault/PreviewMint.sol";
import "./borrowVault/PreviewRedeem.sol";
import "./borrowVault/Deposit.sol";
import "./borrowVault/Withdraw.sol";
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
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';


abstract contract LTV is PreviewWithdraw, PreviewDeposit, PreviewMint, PreviewRedeem, PreviewWithdrawCollateral, PreviewDepositCollateral, PreviewMintCollateral, PreviewRedeemCollateral, Auction, Mint, MintCollateral, Deposit, DepositCollateral, Withdraw, WithdrawCollateral, Redeem, RedeemCollateral, ConvertToAssets, ConvertToShares {
    using uMulDiv for uint256;
    
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

    function firstTimeDeposit(uint256 collateralAssets, uint256 borrowAssets) external onlyOneTime returns (uint256) {
        uint256 sharesInUnderlying = collateralAssets.mulDivDown(getPriceCollateralOracle(), Constants.ORACLE_DIVIDER) -
            borrowAssets.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);
        uint256 sharesInAssets = sharesInUnderlying.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);
        uint256 shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        
        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);
        supply(collateralAssets);

        _mint(msg.sender, shares);
        
        borrow(borrowAssets);
        borrowToken.transfer(msg.sender, borrowAssets);

        return shares;
    }
}
