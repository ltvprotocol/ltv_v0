// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IDummyLending {
    function borrow(address asset, uint256 amount) external;

    function repay(address asset, uint256 amount) external;

    function supply(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;

    function supplyBalance(address asset) external view returns (uint256);

    function borrowBalance(address asset) external view returns (uint256);
}