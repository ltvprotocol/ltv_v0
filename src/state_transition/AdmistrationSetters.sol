// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IWhitelistRegistry} from "../interfaces/IWhitelistRegistry.sol";
import {ISlippageConnector} from "../interfaces/connectors/ISlippageConnector.sol";
import {ILendingConnector} from "../interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "../interfaces/connectors/IOracleConnector.sol";
import {IAdministrationErrors} from "../errors/IAdministrationErrors.sol";
import {IAdministrationEvents} from "../events/IAdministrationEvents.sol";
import {Constants} from "../constants/Constants.sol";
import {BoolReader} from "../math/abstracts/BoolReader.sol";
import {BoolWriter} from "../state_transition/BoolWriter.sol";

contract AdmistrationSetters is BoolWriter, BoolReader, IAdministrationErrors, IAdministrationEvents {
    function _setTargetLtv(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedtargetLtv(dividend, divider));
        require(
            uint256(dividend) * maxSafeLtvDivider <= uint256(divider) * maxSafeLtvDividend
                && dividend * minProfitLtvDivider >= minProfitLtvDividend * divider,
            InvalidLTVSet(
                dividend, divider, maxSafeLtvDividend, maxSafeLtvDivider, minProfitLtvDividend, minProfitLtvDivider
            )
        );
        uint16 oldValue = targetLtvDividend;
        uint16 oldDivider = targetLtvDivider;
        targetLtvDividend = dividend;
        targetLtvDivider = divider;
        emit TargetLtvChanged(oldValue, oldDivider, dividend, divider);
    }

    function _setMaxSafeLtv(uint16 dividend, uint16 divider) internal {
        require(dividend > 0 && dividend <= divider, UnexpectedmaxSafeLtv(dividend, divider));
        require(
            uint256(dividend) * targetLtvDivider >= uint256(targetLtvDividend) * divider,
            InvalidLTVSet(
                targetLtvDividend, targetLtvDivider, dividend, divider, minProfitLtvDividend, minProfitLtvDivider
            )
        );
        uint16 oldDividend = maxSafeLtvDividend;
        uint16 oldDivider = maxSafeLtvDivider;
        maxSafeLtvDividend = dividend;
        maxSafeLtvDivider = divider;
        emit MaxSafeLtvChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setMinProfitLtv(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedminProfitLtv(dividend, divider));
        require(
            uint256(dividend) * targetLtvDivider <= uint256(divider) * targetLtvDividend,
            InvalidLTVSet(targetLtvDividend, targetLtvDivider, maxSafeLtvDividend, maxSafeLtvDivider, dividend, divider)
        );
        uint16 oldDividend = minProfitLtvDividend;
        uint16 oldDivider = minProfitLtvDivider;
        minProfitLtvDividend = dividend;
        minProfitLtvDivider = divider;
        emit MinProfitLtvChanged(oldDividend, oldDivider, dividend, divider);
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
        bool oldValue = _isWhitelistActivated(boolSlot);
        setBool(Constants.IS_WHITELIST_ACTIVATED_BIT, activate);
        emit IsWhitelistActivatedChanged(oldValue, activate);
    }

    function _setWhitelistRegistry(IWhitelistRegistry value) internal {
        require(address(value) != address(0) || !_isWhitelistActivated(boolSlot), WhitelistIsActivated());
        address oldAddress = address(whitelistRegistry);
        whitelistRegistry = value;
        emit WhitelistRegistryUpdated(oldAddress, address(value));
    }

    function _setSlippageConnector(ISlippageConnector _slippageConnector, bytes memory slippageConnectorData)
        internal
    {
        require(address(_slippageConnector) != address(0), ZeroSlippageConnector());
        address oldAddress = address(slippageConnector);
        slippageConnector = _slippageConnector;
        (bool success,) = address(slippageConnector).delegatecall(
            abi.encodeCall(ISlippageConnector.initializeSlippageConnectorData, (slippageConnectorData))
        );
        require(success, FailedToSetSlippageConnector(address(_slippageConnector), slippageConnectorData));
        emit SlippageConnectorUpdated(
            oldAddress, slippageConnectorData, address(_slippageConnector), slippageConnectorData
        );
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

    function _setVaultBalanceAsLendingConnector(
        ILendingConnector _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) internal {
        address oldAddress = address(vaultBalanceAsLendingConnector);
        vaultBalanceAsLendingConnector = ILendingConnector(_vaultBalanceAsLendingConnector);
        (bool success,) = address(vaultBalanceAsLendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeLendingConnectorData, (vaultBalanceAsLendingConnectorGetterData))
        );
        require(
            success,
            FailedToSetVaultBalanceAsLendingConnector(
                address(_vaultBalanceAsLendingConnector), vaultBalanceAsLendingConnectorGetterData
            )
        );
        emit VaultBalanceAsLendingConnectorUpdated(oldAddress, address(_vaultBalanceAsLendingConnector));
    }

    function _setIsDepositDisabled(bool value) internal {
        bool oldValue = _isDepositDisabled(boolSlot);
        setBool(Constants.IS_DEPOSIT_DISABLED_BIT, value);
        emit IsDepositDisabledChanged(oldValue, value);
    }

    function _setIsWithdrawDisabled(bool value) internal {
        bool oldValue = _isWithdrawDisabled(boolSlot);
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
