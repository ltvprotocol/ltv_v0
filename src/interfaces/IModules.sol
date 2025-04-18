// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./reads/IERC20Read.sol";
import "./reads/IAuctionRead.sol";

interface IModules {
    function auctionRead() external view returns (IAuctionRead);

    function auctionWrite() external view returns (address);

    function borrowVaultsRead() external view returns (address);

    function borrowVaultsWrite() external view returns (address);

    function collateralVaultsRead() external view returns (address);

    function collateralVaultsWrite() external view returns (address);

    function erc20Read() external view returns (IERC20Read);

    function erc20Write() external view returns (address);

    function lowLevelRebalancerRead() external view returns (address);

    function lowLevelRebalancerWrite() external view returns (address);
}