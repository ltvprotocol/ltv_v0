// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LendingConnectorState} from "src/structs/state/common/LendingConnectorState.sol";

/**
 * @title IAdministrationModule
 * @notice Interface defining read part of theadministration module for LTV protocol
 */
interface IAdministrationModule {
    /**
     * @dev mdoule function for ILTV.isDepositDisabled. Also receives cached state for subsequent calculations
     */
    function isDepositDisabled(uint8 boolSlot) external view returns (bool);

    /**
     * @dev mdoule function for ILTV.isWithdrawDisabled. Also receives cached state for subsequent calculations
     */
    function isWithdrawDisabled(uint8 boolSlot) external view returns (bool);

    /**
     * @dev mdoule function for ILTV.isWhitelistActivated. Also receives cached state for subsequent calculations
     */
    function isWhitelistActivated(uint8 boolSlot) external view returns (bool);

    /**
     * @dev mdoule function for ILTV.isVaultDeleveraged. Also receives cached state for subsequent calculations
     */
    function isVaultDeleveraged(uint8 boolSlot) external view returns (bool);

    /**
     * @dev mdoule function for ILTV.getLendingConnector. Also receives cached state for subsequent calculations
     */
    function getLendingConnector(LendingConnectorState memory state) external view returns (address);
}
