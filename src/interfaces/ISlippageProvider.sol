// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface ISlippageProvider {
    function collateralSlippage() external view returns (uint256);

    function borrowSlippage() external view returns (uint256);
}
