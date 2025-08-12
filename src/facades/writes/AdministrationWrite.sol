// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";
import "../writes/CommonWrite.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../events/IAdministrationEvents.sol";
import "../../errors/IAdministrationErrors.sol";

abstract contract AdministrationWrite is LTVState, CommonWrite, OwnableUpgradeable, IAdministrationEvents {
    function setTargetLTV(uint128 value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setMaxSafeLTV(uint128 value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setMinProfitLTV(uint128 value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
    }

    function setFeeCollector(address _feeCollector) external {
        _delegate(address(modules.administrationModule()), abi.encode(_feeCollector));
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external {
        _delegate(address(modules.administrationModule()), abi.encode(_maxTotalAssetsInUnderlying));
    }

    function setMaxDeleverageFee(uint256 value) external {
        _delegate(address(modules.administrationModule()), abi.encode(value));
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

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint256 deleverageFee) external {
        _delegate(address(modules.administrationModule()), abi.encode(closeAmountBorrow, deleverageFee));
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

    function setMaxGrowthFee(uint256 _maxGrowthFee) external {
        _delegate(address(modules.administrationModule()), abi.encode(_maxGrowthFee));
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
