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
import {DelegateCallPostCheck} from "src/utils/DelegateCallPostCheck.sol";

/**
 * @title AdministrationSetters
 * @notice contract contains functionality to set administration state
 */
contract AdministrationSetters is
    BoolWriter,
    BoolReader,
    DelegateCallPostCheck,
    IAdministrationErrors,
    IAdministrationEvents
{
    /**
     * @dev implementation of ILTV.setTargetLtv
     */
    function _setTargetLtv(uint16 dividend, uint16 divider) internal {
        require(dividend >= 0 && dividend < divider, UnexpectedtargetLtv(dividend, divider));
        require(
            uint256(dividend) * maxSafeLtvDivider <= uint256(divider) * maxSafeLtvDividend
                && uint256(dividend) * minProfitLtvDivider >= minProfitLtvDividend * uint256(divider),
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
        emit MaxSafeLtvChanged(oldDividend, oldDivider, dividend, divider);
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
        emit MinProfitLtvChanged(oldDividend, oldDivider, dividend, divider);
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
        bool oldValue = _isWhitelistActivated(boolSlot);
        setBool(Constants.IS_WHITELIST_ACTIVATED_BIT, activate);
        emit IsWhitelistActivatedChanged(oldValue, activate);
    }

    /**
     * @dev implementation of ILTV.setWhitelistRegistry
     */
    function _setWhitelistRegistry(IWhitelistRegistry value) internal {
        require(address(value) != address(0) || !_isWhitelistActivated(boolSlot), WhitelistIsActivated());
        address oldAddress = address(whitelistRegistry);
        whitelistRegistry = value;
        emit WhitelistRegistryUpdated(oldAddress, address(value));
    }

    /**
     * @dev implementation of ILTV.setSlippageConnector
     */
    function _setSlippageConnector(ISlippageConnector _slippageConnector, bytes memory slippageConnectorData)
        internal
    {
        require(address(_slippageConnector) != address(0), ZeroSlippageConnector());
        address oldAddress = address(slippageConnector);
        slippageConnector = _slippageConnector;
        (bool success, bytes memory data) = address(slippageConnector).delegatecall(
            abi.encodeCall(ISlippageConnector.initializeSlippageConnectorData, (slippageConnectorData))
        );
        delegateCallPostCheck(address(slippageConnector), success, data);
        emit SlippageConnectorUpdated(
            oldAddress, slippageConnectorData, address(_slippageConnector), slippageConnectorData
        );
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
        require(divider > 0 && dividend <= divider, InvalidMaxGrowthFee(dividend, divider));
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
        (bool success, bytes memory data) = address(vaultBalanceAsLendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeLendingConnectorData, (vaultBalanceAsLendingConnectorGetterData))
        );
        delegateCallPostCheck(address(vaultBalanceAsLendingConnector), success, data);
        emit VaultBalanceAsLendingConnectorUpdated(oldAddress, address(_vaultBalanceAsLendingConnector));
    }

    /**
     * @dev implementation of ILTV.setIsDepositDisabled
     */
    function _setIsDepositDisabled(bool value) internal {
        bool oldValue = _isDepositDisabled(boolSlot);
        setBool(Constants.IS_DEPOSIT_DISABLED_BIT, value);
        emit IsDepositDisabledChanged(oldValue, value);
    }

    /**
     * @dev implementation of ILTV.setIsWithdrawDisabled
     */
    function _setIsWithdrawDisabled(bool value) internal {
        bool oldValue = _isWithdrawDisabled(boolSlot);
        setBool(Constants.IS_WITHDRAW_DISABLED_BIT, value);
        emit IsWithdrawDisabledChanged(oldValue, value);
    }

    /**
     * @dev implementation of ILTV.setIsProtocolPaused
     */
    function _setIsProtocolPaused(bool value) internal {
        bool oldValue = _isProtocolPaused(boolSlot);
        setBool(Constants.IS_PROTOCOL_PAUSED_BIT, value);
        emit IsProtocolPausedChanged(oldValue, value);
    }

    /**
     * @dev implementation of ILTV.setLendingConnector. Makes delegatecall to provided address to initialize
     */
    function _setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData) internal {
        address oldAddress = address(lendingConnector);
        lendingConnector = _lendingConnector;
        (bool success, bytes memory data) = address(lendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeLendingConnectorData, (lendingConnectorData))
        );
        delegateCallPostCheck(address(lendingConnector), success, data);
        emit LendingConnectorUpdated(oldAddress, lendingConnectorData, address(_lendingConnector), lendingConnectorData);
    }

    /**
     * @dev implementation of ILTV.setOracleConnector. Makes delegatecall to provided address to initialize
     */
    function _setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData) internal {
        address oldAddress = address(oracleConnector);
        oracleConnector = _oracleConnector;
        (bool success, bytes memory data) = address(oracleConnector).delegatecall(
            abi.encodeCall(IOracleConnector.initializeOracleConnectorData, (oracleConnectorData))
        );
        delegateCallPostCheck(address(oracleConnector), success, data);
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
