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

/**
 * @title AdmistrationSetters
 * @notice contract contains functionality to set administration state
 */
contract AdmistrationSetters is BoolWriter, BoolReader, IAdministrationErrors, IAdministrationEvents {
    /**
     * @dev implementation of ILTV.setTargetLtv
     */
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
        emit targetLtvChanged(oldValue, oldDivider, dividend, divider);
    }

    /**
     * @dev implementation of ILTV.setMaxSafeLtv
     */
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
        emit maxSafeLtvChanged(oldDividend, oldDivider, dividend, divider);
    }

    /**
     * @dev implementation of ILTV.setMinProfitLtv
     */
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
        emit minProfitLtvChanged(oldDividend, oldDivider, dividend, divider);
    }

    /**
     * @dev implementation of ILTV.setFeeCollector
     */
    function _setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0), ZeroFeeCollector());
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }

    /**
     * @dev implementation of ILTV.setMaxTotalAssetsInUnderlying
     */
    function _setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) internal {
        uint256 oldValue = maxTotalAssetsInUnderlying;
        maxTotalAssetsInUnderlying = _maxTotalAssetsInUnderlying;
        emit MaxTotalAssetsInUnderlyingChanged(oldValue, _maxTotalAssetsInUnderlying);
    }

    /**
     * @dev implementation of ILTV.setMaxDeleverageFee
     */
    function _setMaxDeleverageFee(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend <= divider, InvalidMaxDeleverageFee(dividend, divider));
        uint16 oldDividend = maxDeleverageFeeDividend;
        uint16 oldDivider = maxDeleverageFeeDivider;
        maxDeleverageFeeDividend = dividend;
        maxDeleverageFeeDivider = divider;
        emit MaxDeleverageFeeChanged(oldDividend, oldDivider, dividend, divider);
    }

    /**
     * @dev implementation of ILTV.setIsWhitelistActivated
     */
    function _setIsWhitelistActivated(bool activate) internal {
        require(!activate || address(whitelistRegistry) != address(0), WhitelistRegistryNotSet());
        bool oldValue = isWhitelistActivated();
        setBool(Constants.IS_WHITELIST_ACTIVATED_BIT, activate);
        emit IsWhitelistActivatedChanged(oldValue, activate);
    }

    /**
     * @dev implementation of ILTV.setWhitelistRegistry
     */
    function _setWhitelistRegistry(IWhitelistRegistry value) internal {
        require(address(value) != address(0) || !isWhitelistActivated(), WhitelistIsActivated());
        address oldAddress = address(whitelistRegistry);
        whitelistRegistry = value;
        emit WhitelistRegistryUpdated(oldAddress, address(value));
    }

    /**
     * @dev implementation of ILTV.setSlippageProvider
     */
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

    /**
     * @dev implementation of ILTV.allowDisableFunctions
     */
    function _allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) internal {
        for (uint256 i = 0; i < signatures.length; i++) {
            _isFunctionDisabled[signatures[i]] = isDisabled;
        }
    }

    /**
     * @dev implementation of ILTV.setMaxGrowthFee
     */
    function _setMaxGrowthFee(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend <= divider, InvalidMaxGrowthFee(dividend, divider));
        uint16 oldDividend = maxGrowthFeeDividend;
        uint16 oldDivider = maxGrowthFeeDivider;
        maxGrowthFeeDividend = dividend;
        maxGrowthFeeDivider = divider;
        emit MaxGrowthFeeChanged(oldDividend, oldDivider, dividend, divider);
    }

    /**
     * @dev implementation of ILTV.setVaultBalanceAsLendingConnector. Makes delegatecall to provided address to initialize
     */
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

    /**
     * @dev implementation of ILTV.setIsDepositDisabled
     */
    function _setIsDepositDisabled(bool value) internal {
        bool oldValue = isDepositDisabled();
        setBool(Constants.IS_DEPOSIT_DISABLED_BIT, value);
        emit IsDepositDisabledChanged(oldValue, value);
    }

    /**
     * @dev implementation of ILTV.setIsWithdrawDisabled
     */
    function _setIsWithdrawDisabled(bool value) internal {
        bool oldValue = isWithdrawDisabled();
        setBool(Constants.IS_WITHDRAW_DISABLED_BIT, value);
        emit IsWithdrawDisabledChanged(oldValue, value);
    }

    /**
     * @dev implementation of ILTV.setLendingConnector. Makes delegatecall to provided address to initialize
     */
    function _setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData) internal {
        address oldAddress = address(lendingConnector);
        lendingConnector = _lendingConnector;
        (bool success,) = address(lendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeLendingConnectorData, (lendingConnectorData))
        );
        require(success, FailedToSetLendingConnector(address(_lendingConnector), lendingConnectorData));
        emit LendingConnectorUpdated(oldAddress, lendingConnectorData, address(_lendingConnector), lendingConnectorData);
    }

    /**
     * @dev implementation of ILTV.setOracleConnector. Makes delegatecall to provided address to initialize
     */
    function _setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData) internal {
        address oldAddress = address(oracleConnector);
        oracleConnector = _oracleConnector;
        (bool success,) = address(oracleConnector).delegatecall(
            abi.encodeCall(IOracleConnector.initializeOracleConnectorData, (oracleConnectorData))
        );
        require(success, FailedToSetOracleConnector(address(_oracleConnector), oracleConnectorData));
        emit OracleConnectorUpdated(oldAddress, oracleConnectorData, address(_oracleConnector), oracleConnectorData);
    }

    /**
     * @dev implementation of ILTV.updateEmergencyDeleverager
     */
    function _updateEmergencyDeleverager(address newEmergencyDeleverager) internal {
        address oldEmergencyDeleverager = emergencyDeleverager;
        emergencyDeleverager = newEmergencyDeleverager;
        emit EmergencyDeleveragerUpdated(oldEmergencyDeleverager, newEmergencyDeleverager);
    }

    /**
     * @dev implementation of ILTV.updateGovernor
     */
    function _updateGovernor(address newGovernor) internal {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorUpdated(oldGovernor, newGovernor);
    }

    /**
     * @dev implementation of ILTV.updateGuardian
     */
    function _updateGuardian(address newGuardian) internal {
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }
}
