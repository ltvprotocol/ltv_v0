// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ISlippageProvider
 * @notice Interface defines slippage provider structure for integration with LTV protocol.
 */
interface ISlippageProvider {
    /**
     * @dev Get the collateral slippage
     */
    function collateralSlippage(bytes calldata slippageProviderGetterData) external view returns (uint256);
    /**
     * @dev Get the borrow slippage
     */
    function borrowSlippage(bytes calldata slippageProviderGetterData) external view returns (uint256);

    /**
     * @dev Initialize the slippage provider data for next calls of getters.
     */
    function initializeSlippageProviderData(bytes calldata slippageProviderData) external;
}
