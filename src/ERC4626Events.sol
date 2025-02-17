// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

contract ERC4626Events {
  event Deposit(address sender, address owner, uint256 assets, uint256 shares);
  event Withdraw(address sender, address receiver, address owner, uint256 assets, uint256 shares);
  event DepositCollateral(address sender, address owner, uint256 collateralAssets, uint256 shares);
  event WithdrawCollateral(address sender, address receiver, address owner, uint256 collateralAssets, uint256 shares);
}