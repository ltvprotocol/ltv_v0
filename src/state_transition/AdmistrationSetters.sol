// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../errors/IAdministrationErrors.sol";
import "../events/IAdministrationEvents.sol";
import "../states/LTVState.sol";
import "../Constants.sol";

contract AdmistrationSetters is LTVState, IAdministrationErrors, IAdministrationEvents {
    function _setTargetLTV(uint128 value) internal {
        require(value > 0 && value < Constants.LTV_DIVIDER, UnexpectedTargetLTV(value));
        require(value <= maxSafeLTV && value >= minProfitLTV, InvalidLTVSet(value, maxSafeLTV, minProfitLTV));
        uint128 oldValue = targetLTV;
        targetLTV = value;
        emit TargetLTVChanged(oldValue, targetLTV);
    }

    function _setMaxSafeLTV(uint128 value) internal {
        require(value > 0 && value < Constants.LTV_DIVIDER, UnexpectedMaxSafeLTV(value));
        require(value >= targetLTV, InvalidLTVSet(targetLTV, value, minProfitLTV));
        uint128 oldValue = maxSafeLTV;
        maxSafeLTV = value;
        emit MaxSafeLTVChanged(oldValue, value);
    }

    function _setMinProfitLTV(uint128 value) internal {
        require(value > 0 && value < Constants.LTV_DIVIDER, UnexpectedMinProfitLTV(value));
        require(value <= targetLTV, InvalidLTVSet(targetLTV, maxSafeLTV, value));
        uint128 oldValue = minProfitLTV;
        minProfitLTV = value;
        emit MinProfitLTVChanged(oldValue, value);
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

    function _setMaxDeleverageFee(uint256 value) internal {
        require(value < 10 ** 18, InvalidMaxDeleverageFee(value));
        uint256 oldValue = maxDeleverageFee;
        maxDeleverageFee = value;
        emit MaxDeleverageFeeChanged(oldValue, value);
    }

    function _setIsWhitelistActivated(bool activate) internal {
        require(!activate || address(whitelistRegistry) != address(0), WhitelistRegistryNotSet());
        bool oldValue = isWhitelistActivated;
        isWhitelistActivated = activate;
        emit IsWhitelistActivatedChanged(oldValue, activate);
    }

    function _setWhitelistRegistry(IWhitelistRegistry value) internal {
        require(address(value) != address(0) || !isWhitelistActivated, WhitelistIsActivated());
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

    function _setMaxGrowthFee(uint256 _maxGrowthFee) internal {
        require(_maxGrowthFee <= 10 ** 18, InvalidMaxGrowthFee(_maxGrowthFee));
        uint256 oldValue = maxGrowthFee;
        maxGrowthFee = _maxGrowthFee;
        emit MaxGrowthFeeChanged(oldValue, _maxGrowthFee);
    }

    function _setIsDepositDisabled(bool value) internal {
        bool oldValue = isDepositDisabled;
        isDepositDisabled = value;
        emit IsDepositDisabledChanged(oldValue, value);
    }

    function _setIsWithdrawDisabled(bool value) internal {
        bool oldValue = isWithdrawDisabled;
        isWithdrawDisabled = value;
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
