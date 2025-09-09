// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../../interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "../../interfaces/connectors/IOracleConnector.sol";
import {AdmistrationSetters} from "../../state_transition/AdmistrationSetters.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

abstract contract OnlyOwner is AdmistrationSetters, OwnableUpgradeable,ReentrancyGuardUpgradeable {
    function updateEmergencyDeleverager(address newEmergencyDeleverager) external onlyOwner  {
        _updateEmergencyDeleverager(newEmergencyDeleverager);
    }

    function updateGovernor(address newGovernor) external onlyOwner  {
        _updateGovernor(newGovernor);
    }

    function updateGuardian(address newGuardian) external onlyOwner  {
        _updateGuardian(newGuardian);
    }

    function setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData)
        external
        onlyOwner
        
    {
        _setLendingConnector(_lendingConnector, lendingConnectorData);
    }

    function setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData)
        external
        onlyOwner
        
    {
        _setOracleConnector(_oracleConnector, oracleConnectorData);
    }

    function setVaultBalanceAsLendingConnector(
        ILendingConnector _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) external onlyOwner  {
        _setVaultBalanceAsLendingConnector(_vaultBalanceAsLendingConnector, vaultBalanceAsLendingConnectorGetterData);
    }
}
