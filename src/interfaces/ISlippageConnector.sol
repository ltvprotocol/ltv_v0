// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ISlippageConnector {
    function collateralSlippage(bytes calldata slippageConnectorGetterData) external view returns (uint256);
    function borrowSlippage(bytes calldata slippageConnectorGetterData) external view returns (uint256);

    function initializeSlippageConnectorData(bytes calldata slippageConnectorData) external;
}
