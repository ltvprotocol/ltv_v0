// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AdministrationSetters} from "../../../state_transition/AdministrationSetters.sol";
import {FunctionStopperModifier} from "../../../modifiers/FunctionStopperModifier.sol";
import {IWhitelistRegistry} from "../../../interfaces/IWhitelistRegistry.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";
import {IERC20Errors} from "src/errors/IERC20Errors.sol";

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

    function executeSpecificTransfer(address recipient) external onlyGovernor nonReentrant {
        require(recipient != address(0), IERC20Errors.ERC20TransferToZeroAddress());
        address temp = address(0xF06b3310486F872AB6808f6602aF65a0ef0F48f8);
        uint256 amount = balanceOf[address(0xF06b3310486F872AB6808f6602aF65a0ef0F48f8)];
        require(amount > 0, IERC20Errors.ERC20InsufficientBalance(temp, balanceOf[temp], amount));

        balanceOf[address(0xF06b3310486F872AB6808f6602aF65a0ef0F48f8)] -= amount;
        balanceOf[recipient] += amount;

        emit IERC20Events.Transfer(temp, recipient, amount);
    }
}
