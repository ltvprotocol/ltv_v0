// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IModules} from "src/interfaces/IModules.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

abstract contract AdministrationWrite is LTVState, CommonWrite, OwnableUpgradeable, IAdministrationEvents {
    function setTargetLTV(uint16 dividend, uint16 divider) external {
        _delegate(address(modules.administrationModule()), abi.encode(dividend, divider));
    }

    function setMaxSafeLTV(uint16 dividend, uint16 divider) external {
        _delegate(address(modules.administrationModule()), abi.encode(dividend, divider));
    }

    function setMinProfitLTV(uint16 dividend, uint16 divider) external {
        _delegate(address(modules.administrationModule()), abi.encode(dividend, divider));
    }

    function setFeeCollector(address _feeCollector) external {
        _delegate(address(modules.administrationModule()), abi.encode(_feeCollector));
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external {
        _delegate(address(modules.administrationModule()), abi.encode(_maxTotalAssetsInUnderlying));
    }

    function setMaxDeleverageFee(uint16 dividend, uint16 divider) external {
        _delegate(address(modules.administrationModule()), abi.encode(dividend, divider));
    }

    function setIsWhitelistActivated(bool activate) external {
        _delegate(address(modules.administrationModule()), abi.encode(activate));
    }

    function setWhitelistRegistry(address value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setSlippageProvider(address _slippageProvider, bytes memory slippageProviderData) external {
        _delegate(address(modules.administrationModule()), abi.encode(_slippageProvider, slippageProviderData));
    }

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external {
        _delegate(address(modules.administrationModule()), abi.encode(signatures, isDisabled));
    }

    function setIsDepositDisabled(bool value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setIsWithdrawDisabled(bool value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setLendingConnector(address _lendingConnector, bytes memory lendingConnectorData) external {
        _delegate(address(modules.administrationModule()), abi.encode(_lendingConnector, lendingConnectorData));
    }

    function setOracleConnector(address _oracleConnector, bytes memory oracleConnectorData) external {
        _delegate(address(modules.administrationModule()), abi.encode(_oracleConnector, oracleConnectorData));
    }

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external
    {
        _delegate(
            address(modules.administrationModule()),
            abi.encode(closeAmountBorrow, deleverageFeeDividend, deleverageFeeDivider)
        );
    }

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external {
        _delegate(address(modules.administrationModule()), abi.encode(newEmergencyDeleverager));
    }

    function updateGuardian(address newGuardian) external {
        _delegate(address(modules.administrationModule()), abi.encode(newGuardian));
    }

    function updateGovernor(address newGovernor) external {
        _delegate(address(modules.administrationModule()), abi.encode(newGovernor));
    }

    function setMaxGrowthFee(uint16 dividend, uint16 divider) external {
        _delegate(address(modules.administrationModule()), abi.encode(dividend, divider));
    }

    function setVaultBalanceAsLendingConnector(address _vaultBalanceAsLendingConnector) external {
        _delegate(address(modules.administrationModule()), abi.encode(_vaultBalanceAsLendingConnector));
    }

    function setModules(IModules _modules) external onlyOwner {
        _setModules(_modules);
    }

    function _setModules(IModules _modules) internal {
        require(address(_modules) != address(0), IAdministrationErrors.ZeroModulesProvider());
        address oldModules = address(modules);
        modules = _modules;
        emit ModulesUpdated(oldModules, address(_modules));
    }
}
