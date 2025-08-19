// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {ISlippageProvider} from "src/interfaces/ISlippageProvider.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/IOracleConnector.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";
import {Constants} from "src/Constants.sol";
import {BoolReader} from "src/state_reader/BoolReader.sol";
import {BoolWriter} from "src/state_transition/BoolWriter.sol";

contract AdmistrationSetters is BoolWriter, BoolReader, IAdministrationErrors, IAdministrationEvents {
    function _setTargetLTV(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedTargetLTV(dividend, divider));
        require(
            uint256(dividend) * maxSafeLTVDivider <= uint256(divider) * maxSafeLTVDividend
                && dividend * minProfitLTVDivider >= minProfitLTVDividend * divider,
            InvalidLTVSet(
                dividend, divider, maxSafeLTVDividend, maxSafeLTVDivider, minProfitLTVDividend, minProfitLTVDivider
            )
        );
        uint16 oldValue = targetLTVDividend;
        uint16 oldDivider = targetLTVDivider;
        targetLTVDividend = dividend;
        targetLTVDivider = divider;
        emit TargetLTVChanged(oldValue, oldDivider, dividend, divider);
    }

    function _setMaxSafeLTV(uint16 dividend, uint16 divider) internal {
        require(dividend > 0 && dividend <= divider, UnexpectedMaxSafeLTV(dividend, divider));
        require(
            uint256(dividend) * targetLTVDivider >= uint256(targetLTVDividend) * divider,
            InvalidLTVSet(
                targetLTVDividend, targetLTVDivider, dividend, divider, minProfitLTVDividend, minProfitLTVDivider
            )
        );
        uint16 oldDividend = maxSafeLTVDividend;
        uint16 oldDivider = maxSafeLTVDivider;
        maxSafeLTVDividend = dividend;
        maxSafeLTVDivider = divider;
        emit MaxSafeLTVChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setMinProfitLTV(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedMinProfitLTV(dividend, divider));
        require(
            uint256(dividend) * targetLTVDivider <= uint256(divider) * targetLTVDividend,
            InvalidLTVSet(targetLTVDividend, targetLTVDivider, maxSafeLTVDividend, maxSafeLTVDivider, dividend, divider)
        );
        uint16 oldDividend = minProfitLTVDividend;
        uint16 oldDivider = minProfitLTVDivider;
        minProfitLTVDividend = dividend;
        minProfitLTVDivider = divider;
        emit MinProfitLTVChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0), ZeroFeeCollector());
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }

    function _setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) internal {
        uint256 oldValue = maxTotalAssetsInUnderlying;
        maxTotalAssetsInUnderlying = _maxTotalAssetsInUnderlying;
        emit MaxTotalAssetsInUnderlyingChanged(oldValue, _maxTotalAssetsInUnderlying);
    }

    function _setMaxDeleverageFee(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend <= divider, InvalidMaxDeleverageFee(dividend, divider));
        uint16 oldDividend = maxDeleverageFeeDividend;
        uint16 oldDivider = maxDeleverageFeeDivider;
        maxDeleverageFeeDividend = dividend;
        maxDeleverageFeeDivider = divider;
        emit MaxDeleverageFeeChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setIsWhitelistActivated(bool activate) internal {
        require(!activate || address(whitelistRegistry) != address(0), WhitelistRegistryNotSet());
        bool oldValue = isWhitelistActivated();
        setBool(Constants.IS_WHITELIST_ACTIVATED_BIT, activate);
        emit IsWhitelistActivatedChanged(oldValue, activate);
    }

    function _setWhitelistRegistry(IWhitelistRegistry value) internal {
        require(address(value) != address(0) || !isWhitelistActivated(), WhitelistIsActivated());
        address oldAddress = address(whitelistRegistry);
        whitelistRegistry = value;
        emit WhitelistRegistryUpdated(oldAddress, address(value));
    }

    function _setSlippageProvider(ISlippageProvider _slippageProvider, bytes memory slippageProviderData) internal {
        require(address(_slippageProvider) != address(0), ZeroSlippageProvider());
        address oldAddress = address(slippageProvider);
        slippageProvider = _slippageProvider;
        (bool success,) = address(slippageProvider).delegatecall(
            abi.encodeCall(ISlippageProvider.initializeSlippageProviderData, (slippageProviderData))
        );
        require(success, FailedToSetSlippageProvider(address(_slippageProvider), slippageProviderData));
        emit SlippageProviderUpdated(oldAddress, slippageProviderData, address(_slippageProvider), slippageProviderData);
    }

    function _allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) internal {
        for (uint256 i = 0; i < signatures.length; i++) {
            _isFunctionDisabled[signatures[i]] = isDisabled;
        }
    }

    function _setMaxGrowthFee(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend <= divider, InvalidMaxGrowthFee(dividend, divider));
        uint16 oldDividend = maxGrowthFeeDividend;
        uint16 oldDivider = maxGrowthFeeDivider;
        maxGrowthFeeDividend = dividend;
        maxGrowthFeeDivider = divider;
        emit MaxGrowthFeeChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setVaultBalanceAsLendingConnector(address _vaultBalanceAsLendingConnector) internal {
        address oldAddress = address(vaultBalanceAsLendingConnector);
        vaultBalanceAsLendingConnector = ILendingConnector(_vaultBalanceAsLendingConnector);
        emit VaultBalanceAsLendingConnectorUpdated(oldAddress, _vaultBalanceAsLendingConnector);
    }

    function _setIsDepositDisabled(bool value) internal {
        bool oldValue = isDepositDisabled();
        setBool(Constants.IS_DEPOSIT_DISABLED_BIT, value);
        emit IsDepositDisabledChanged(oldValue, value);
    }

    function _setIsWithdrawDisabled(bool value) internal {
        bool oldValue = isWithdrawDisabled();
        setBool(Constants.IS_WITHDRAW_DISABLED_BIT, value);
        emit IsWithdrawDisabledChanged(oldValue, value);
    }

    function _setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData) internal {
        address oldAddress = address(lendingConnector);
        lendingConnector = _lendingConnector;
        (bool success,) = address(lendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeLendingConnectorData, (lendingConnectorData))
        );
        require(success, FailedToSetLendingConnector(address(_lendingConnector), lendingConnectorData));
        emit LendingConnectorUpdated(oldAddress, lendingConnectorData, address(_lendingConnector), lendingConnectorData);
    }

    function _setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData) internal {
        address oldAddress = address(oracleConnector);
        oracleConnector = _oracleConnector;
        (bool success,) = address(oracleConnector).delegatecall(
            abi.encodeCall(IOracleConnector.initializeOracleConnectorData, (oracleConnectorData))
        );
        require(success, FailedToSetOracleConnector(address(_oracleConnector), oracleConnectorData));
        emit OracleConnectorUpdated(oldAddress, oracleConnectorData, address(_oracleConnector), oracleConnectorData);
    }

    function _updateEmergencyDeleverager(address newEmergencyDeleverager) internal {
        address oldEmergencyDeleverager = emergencyDeleverager;
        emergencyDeleverager = newEmergencyDeleverager;
        emit EmergencyDeleveragerUpdated(oldEmergencyDeleverager, newEmergencyDeleverager);
    }

    function _updateGovernor(address newGovernor) internal {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorUpdated(oldGovernor, newGovernor);
    }

    function _updateGuardian(address newGuardian) internal {
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }
}
