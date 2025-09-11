// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ILendingConnector
 * @notice Interface defines connector structure for integration with LTV protocol.
 */
interface ILendingConnector {
    /**
     * @dev Supply assets to the lending protocol
     */
    function supply(uint256 assets) external;
    /**
     * @dev Withdraw assets from the lending protocol
     */
    function withdraw(uint256 assets) external;
    /**
     * @dev Borrow assets from the lending protocol
     */
    function borrow(uint256 assets) external;
    /**
     * @dev Repay assets to the lending protocol
     */
    function repay(uint256 assets) external;
    /**
     * @dev Get real collateral assets balance from the lending protocol
     */
    function getRealCollateralAssets(bool isDeposit, bytes calldata data) external view returns (uint256);
    /**
     * @dev Get real borrow assets balance from the lending protocol
     */
    function getRealBorrowAssets(bool isDeposit, bytes calldata data) external view returns (uint256);
    /**
     * @dev Initializes lending connector, sets lending connector data for future calls of getters.
     */
    function initializeLendingConnectorData(bytes memory data) external;
}
