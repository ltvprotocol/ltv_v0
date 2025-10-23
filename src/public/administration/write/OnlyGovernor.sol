// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AdministrationSetters} from "../../../state_transition/AdministrationSetters.sol";
import {FunctionStopperModifier} from "../../../modifiers/FunctionStopperModifier.sol";
import {IWhitelistRegistry} from "../../../interfaces/IWhitelistRegistry.sol";

/**
 * @title OnlyGovernor
 * @notice This contract contains only governor public function implementation.
 */
abstract contract OnlyGovernor is
    AdministrationSetters,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    AdministrationModifiers
{
    /**
     * @dev see ILTV.setTargetLtv
     */
    function setTargetLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setTargetLtv(dividend, divider);
    }

    /**
     * @dev see ILTV.setMaxSafeLtv
     */
    function setMaxSafeLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxSafeLtv(dividend, divider);
    }

    /**
     * @dev see ILTV.setMinProfitLtv
     */
    function setMinProfitLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMinProfitLtv(dividend, divider);
    }

    /**
     * @dev see ILTV.setFeeCollector
     */
    function setFeeCollector(address _feeCollector) external isFunctionAllowed onlyGovernor nonReentrant {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @dev see ILTV.setMaxTotalAssetsInUnderlying
     */
    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxTotalAssetsInUnderlying(_maxTotalAssetsInUnderlying);
    }

    /**
     * @dev see ILTV.setMaxDeleverageFee
     */
    function setMaxDeleverageFee(uint16 dividend, uint16 divider)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxDeleverageFee(dividend, divider);
    }

    /**
     * @dev see ILTV.setIsWhitelistActivated
     */
    function setIsWhitelistActivated(bool activate) external isFunctionAllowed onlyGovernor nonReentrant {
        _setIsWhitelistActivated(activate);
    }

    /**
     * @dev see ILTV.setWhitelistRegistry
     */
    function setWhitelistRegistry(IWhitelistRegistry value) external isFunctionAllowed onlyGovernor nonReentrant {
        _setWhitelistRegistry(value);
    }

    /**
     * @dev see ILTV.setMaxGrowthFee
     */
    function setMaxGrowthFee(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxGrowthFee(dividend, divider);
    }

    /**
     * @dev see ILTV.setSlippageConnectorData
     */
    function setSlippageConnectorData(bytes memory slippageConnectorData)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setSlippageConnectorData(slippageConnectorData);
    }

    /**
     * @dev see ILTV.setIsSoftLiquidationEnabledForAnyone
     */
    function setIsSoftLiquidationEnabledForAnyone(bool value) external isFunctionAllowed onlyGovernor nonReentrant {
        _setIsSoftLiquidationEnabledForAnyone(value);
    }

    /**
     * @dev see ILTV.setSoftLiquidationFee
     */
    function setSoftLiquidationFee(uint16 dividend, uint16 divider)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setSoftLiquidationFee(dividend, divider);
    }

    /**
     * @dev see ILTV.setSoftLiquidationLtv
     */
    function setSoftLiquidationLtv(uint16 dividend, uint16 divider)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setSoftLiquidationLtv(dividend, divider);
    }
}
