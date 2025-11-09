// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "../../interfaces/connectors/ILendingConnector.sol";
import {LTVState} from "../../states/LTVState.sol";

/**
 * @title VaultBalanceAsLendingConnector
 * @notice Connector to switch to after deleverage and withdrawal event.
 *
 * @dev Current connector expects only collateral assets left in the vault.
 * It makes protocol balance interpreted as lending connector. Borrow, supply and
 * repay operations are not allowed in this case.
 */
contract VaultBalanceAsLendingConnector is LTVState, ILendingConnector {
    error UnexpectedBorrowCall();
    error UnexpectedRepayCall();
    error UnexpectedSupplyCall();

    function getRealCollateralAssets(bool, bytes calldata data) external view returns (uint256) {
        (address collateralToken,) = abi.decode(data, (address, address));
        return IERC20(collateralToken).balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool, bytes calldata data) external view returns (uint256) {
        (, address borrowToken) = abi.decode(data, (address, address));
        return IERC20(borrowToken).balanceOf(msg.sender);
    }

    function withdraw(uint256) external {}

    function borrow(uint256) external pure {
        revert UnexpectedBorrowCall();
    }

    function repay(uint256) external pure {
        revert UnexpectedRepayCall();
    }

    function supply(uint256) external pure {
        revert UnexpectedSupplyCall();
    }

    function initializeLendingConnectorData(bytes memory) external {
        vaultBalanceAsLendingConnectorGetterData = abi.encode(address(collateralToken), address(borrowToken));
    }
}
