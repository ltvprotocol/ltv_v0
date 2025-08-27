// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ISlippageProvider {
    function collateralSlippage(bytes calldata slippageProviderGetterData) external view returns (uint256);
    function borrowSlippage(bytes calldata slippageProviderGetterData) external view returns (uint256);

    function initializeSlippageProviderData(bytes calldata slippageProviderData) external;
}
