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
    function _setTargetLtv(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedtargetLtv(dividend, divider));
        require(
            dividend * maxSafeLtvDivider <= divider * maxSafeLtvDividend
                && dividend * minProfitLtvDivider >= minProfitLtvDividend * divider,
            InvalidLTVSet(
                dividend, divider, maxSafeLtvDividend, maxSafeLtvDivider, minProfitLtvDividend, minProfitLtvDivider
            )
        );
        uint16 oldValue = targetLtvDividend;
        uint16 oldDivider = targetLtvDivider;
        targetLtvDividend = dividend;
        targetLtvDivider = divider;
        emit targetLtvChanged(oldValue, oldDivider, dividend, divider);
    }

    function _setMaxSafeLtv(uint16 dividend, uint16 divider) internal {
        require(dividend > 0 && dividend <= divider, UnexpectedmaxSafeLtv(dividend, divider));
        require(
            dividend * targetLtvDivider >= targetLtvDividend * divider,
            InvalidLTVSet(
                targetLtvDividend, targetLtvDivider, dividend, divider, minProfitLtvDividend, minProfitLtvDivider
            )
        );
        uint16 oldDividend = maxSafeLtvDividend;
        uint16 oldDivider = maxSafeLtvDivider;
        maxSafeLtvDividend = dividend;
        maxSafeLtvDivider = divider;
        emit maxSafeLtvChanged(oldDividend, oldDivider, dividend, divider);
    }

    function _setMinProfitLtv(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedminProfitLtv(dividend, divider));
        require(
            dividend * targetLtvDivider <= divider * targetLtvDividend,
            InvalidLTVSet(targetLtvDividend, targetLtvDivider, maxSafeLtvDividend, maxSafeLtvDivider, dividend, divider)
        );
        uint16 oldDividend = minProfitLtvDividend;
        uint16 oldDivider = minProfitLtvDivider;
        minProfitLtvDividend = dividend;
        minProfitLtvDivider = divider;
        emit minProfitLtvChanged(oldDividend, oldDivider, dividend, divider);
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

    function _setSlippageProvider(ISlippageProvider _slippageProvider) internal {
        require(address(_slippageProvider) != address(0), ZeroSlippageProvider());
        address oldAddress = address(slippageProvider);
        slippageProvider = _slippageProvider;
        emit SlippageProviderUpdated(oldAddress, address(_slippageProvider));
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

    function _setLendingConnector(ILendingConnector _lendingConnector) internal {
        address oldAddress = address(lendingConnector);
        lendingConnector = _lendingConnector;
        emit LendingConnectorUpdated(oldAddress, address(_lendingConnector));
    }

    function _setOracleConnector(IOracleConnector _oracleConnector) internal {
        address oldAddress = address(oracleConnector);
        oracleConnector = _oracleConnector;
        emit OracleConnectorUpdated(oldAddress, address(_oracleConnector));
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
