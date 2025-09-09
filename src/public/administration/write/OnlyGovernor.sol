// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AdmistrationSetters} from "../../../state_transition/AdmistrationSetters.sol";
import {FunctionStopperModifier} from "../../../modifiers/FunctionStopperModifier.sol";
import {IWhitelistRegistry} from "../../../interfaces/IWhitelistRegistry.sol";
import {ISlippageConnector} from "../../../interfaces/connectors/ISlippageConnector.sol";

abstract contract OnlyGovernor is
    AdmistrationSetters,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    AdministrationModifiers
{
    function setTargetLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setTargetLtv(dividend, divider);
    }

    function setMaxSafeLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxSafeLtv(dividend, divider);
    }

    function setMinProfitLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMinProfitLtv(dividend, divider);
    }

    function setFeeCollector(address _feeCollector) external isFunctionAllowed onlyGovernor nonReentrant {
        _setFeeCollector(_feeCollector);
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxTotalAssetsInUnderlying(_maxTotalAssetsInUnderlying);
    }

    function setMaxDeleverageFee(uint16 dividend, uint16 divider)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxDeleverageFee(dividend, divider);
    }

    function setIsWhitelistActivated(bool activate) external isFunctionAllowed onlyGovernor nonReentrant {
        _setIsWhitelistActivated(activate);
    }

    function setWhitelistRegistry(IWhitelistRegistry value) external isFunctionAllowed onlyGovernor nonReentrant {
        _setWhitelistRegistry(value);
    }

    function setSlippageConnector(ISlippageConnector _slippageConnector, bytes memory slippageConnectorData)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setSlippageConnector(_slippageConnector, slippageConnectorData);
    }

    function setMaxGrowthFee(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxGrowthFee(dividend, divider);
    }
}
