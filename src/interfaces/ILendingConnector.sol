// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface ILendingConnector {
    function supply(uint256 assets) external;
    function withdraw(uint256 assets) external;
    function borrow(uint256 assets) external;
    function repay(uint256 assets) external;
    function getRealCollateralAssets() external view returns (uint256);
    function getRealBorrowAssets() external view returns (uint256);
}