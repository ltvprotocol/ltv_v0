// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../../../interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "../../../interfaces/connectors/IOracleConnector.sol";
import {AdministrationSetters} from "../../../state_transition/AdministrationSetters.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OnlyOwner
 * @notice This contract contains only owner public function implementation.
 */
abstract contract OnlyOwner is AdministrationSetters, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    /**
     * @dev see ILTV.updateEmergencyDeleverager
     */
    function updateEmergencyDeleverager(address newEmergencyDeleverager) external onlyOwner nonReentrant {
        _updateEmergencyDeleverager(newEmergencyDeleverager);
    }

    /**
     * @dev see ILTV.updateGovernor
     */
    function updateGovernor(address newGovernor) external onlyOwner nonReentrant {
        _updateGovernor(newGovernor);
    }

    /**
     * @dev see ILTV.updateGuardian
     */
    function updateGuardian(address newGuardian) external onlyOwner nonReentrant {
        _updateGuardian(newGuardian);
    }

    /**
     * @dev see ILTV.setLendingConnector
     */
    function setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData)
        external
        onlyOwner
        nonReentrant
    {
        _setLendingConnector(_lendingConnector, lendingConnectorData);
    }

    /**
     * @dev see ILTV.setOracleConnector
     */
    function setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData)
        external
        onlyOwner
        nonReentrant
    {
        _setOracleConnector(_oracleConnector, oracleConnectorData);
    }

    /**
     * @dev see ILTV.setVaultBalanceAsLendingConnector
     */
    function setVaultBalanceAsLendingConnector(
        ILendingConnector _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) external onlyOwner nonReentrant {
        _setVaultBalanceAsLendingConnector(_vaultBalanceAsLendingConnector, vaultBalanceAsLendingConnectorGetterData);
    }

    /**
     * @dev see ILTV.sweep
     */
    function sweep(address token, uint256 amount) external onlyOwner nonReentrant {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
