// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ISlippageConnector
 * @notice Interface defines slippage connector structure for integration with LTV protocol.
 */
interface ISlippageConnector {
    /**
     * @dev Get the collateral slippage
     */
    function collateralSlippage(bytes calldata slippageConnectorGetterData) external view returns (uint256);
    /**
     * @dev Get the borrow slippage
     */
    function borrowSlippage(bytes calldata slippageConnectorGetterData) external view returns (uint256);

    /**
     * @dev Initialize the slippage provider data for next calls of getters.
     */
    function initializeSlippageConnectorData(bytes calldata slippageConnectorData) external;
}
