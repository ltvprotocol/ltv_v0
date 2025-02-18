// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IHodlMyBeerLending {
    /// @notice Get the supply balance for a given address
    /// @param account The address to check
    /// @return The supply balance
    function supplyCollateralBalance(address account) external view returns (uint256);

    /// @notice Get the borrow balance for a given address
    /// @param account The address to check
    /// @return The borrow balance
    function borrowBalance(address account) external view returns (uint256);

    function supplyBalance(address account) external view returns (uint256);

    /// @notice Get the borrow token address
    function borrowToken() external view returns (address);

    /// @notice Get the collateral token address
    function collateralToken() external view returns (address);

    /// @notice Get the oracle address
    function oracle() external view returns (address);

    /// @notice Initialize the lending contract
    /// @param _borrowToken The address of the token that can be borrowed
    /// @param _collateralToken The address of the token that can be used as collateral
    /// @param _oracle The address of the price oracle
    function initialize(
        address _borrowToken,
        address _collateralToken,
        address _oracle
    ) external;

    /// @notice Borrow tokens against supplied collateral
    /// @param amount The amount of tokens to borrow
    function borrow(uint256 amount) external;

    /// @notice Repay borrowed tokens
    /// @param amount The amount of tokens to repay
    function repay(uint256 amount) external;

    /// @notice Supply collateral tokens
    /// @param amount The amount of tokens to supply
    function supplyCollateral(uint256 amount) external;

    /// @notice Withdraw supplied collateral tokens
    /// @param amount The amount of tokens to withdraw
    function withdrawCollateral(uint256 amount) external;

    function supply(uint256 amount) external;

    function withdraw(uint256 amount) external;

}