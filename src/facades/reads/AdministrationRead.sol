// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GetLendingConnectorStateReader} from "../../state_reader/administration/GetLendingConnectorStateReader.sol";
import {ILendingConnector} from "../../interfaces/connectors/ILendingConnector.sol";

/**
 * @title AdministrationRead
 * @notice This contract contains all the read functions for the administration part of the LTV protocol.
 * It retrieves appropriate function state and delegates all the calculations to the administration module.
 */
contract AdministrationRead is GetLendingConnectorStateReader {
    /**
     * @dev see ILTV.isDepositDisabled
     */
    function isDepositDisabled() external view returns (bool) {
        return modules.administrationModule().isDepositDisabled(boolSlot);
    }

    /**
     * @dev see ILTV.isWithdrawDisabled
     */
    function isWithdrawDisabled() external view returns (bool) {
        return modules.administrationModule().isWithdrawDisabled(boolSlot);
    }

    /**
     * @dev see ILTV.isWhitelistActivated
     */
    function isWhitelistActivated() external view returns (bool) {
        return modules.administrationModule().isWhitelistActivated(boolSlot);
    }

    /**
     * @dev see ILTV.isVaultDeleveraged
     */
    function isVaultDeleveraged() external view returns (bool) {
        return modules.administrationModule().isVaultDeleveraged(boolSlot);
    }

    /**
     * @dev see ILTV.isProtocolPaused
     */
    function isProtocolPaused() external view returns (bool) {
        return modules.administrationModule().isProtocolPaused(boolSlot);
    }

    /**
     * @dev see ILTV.getLendingConnector
     */
    function getLendingConnector() external view returns (ILendingConnector) {
        return ILendingConnector(modules.administrationModule().getLendingConnector(getLendingConnectorState()));
    }
}
