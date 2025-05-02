// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAdministration {
    function owner() external view returns (address);

    function guardian() external view returns (address);

    function governor() external view returns (address);

    function deleverageWithdrawer() external view returns (address);
}
