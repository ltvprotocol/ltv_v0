// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
/**
 * @title AdministrationWrite
 * @notice This contract contains all the write functions for the administration part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the administration module.
 */

abstract contract AdministrationWrite is LTVState, CommonWrite, FacadeImplementationState {
    /**
     * @dev see ILTV.setTargetLtv
     */
    function setTargetLtv(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setMaxSafeLtv
     */
    function setMaxSafeLtv(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setMinProfitLtv
     */
    function setMinProfitLtv(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setFeeCollector
     */
    function setFeeCollector(address _feeCollector) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(_feeCollector));
    }

    /**
     * @dev see ILTV.setMaxTotalAssetsInUnderlying
     */
    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(_maxTotalAssetsInUnderlying));
    }

    /**
     * @dev see ILTV.setMaxDeleverageFee
     */
    function setMaxDeleverageFee(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setIsWhitelistActivated
     */
    function setIsWhitelistActivated(bool activate) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(activate));
    }

    /**
     * @dev see ILTV.setWhitelistRegistry
     */
    function setWhitelistRegistry(address value) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(value));
    }

    /**
     * @dev see ILTV.setIsSoftLiquidationEnabledForAnyone
     */
    function setIsSoftLiquidationEnabledForAnyone(bool value) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(value));
    }

    /**
     * @dev see ILTV.setSlippageConnector
     */
    function setSlippageConnector(address _slippageConnector, bytes memory slippageConnectorData) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(_slippageConnector, slippageConnectorData));
    }

    /**
     * @dev see ILTV.allowDisableFunctions
     */
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(signatures, isDisabled));
    }

    /**
     * @dev see ILTV.setIsDepositDisabled
     */
    function setIsDepositDisabled(bool value) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(value));
    }

    /**
     * @dev see ILTV.setIsWithdrawDisabled
     */
    function setIsWithdrawDisabled(bool value) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(value));
    }

    /**
     * @dev see ILTV.setIsProtocolPaused
     */
    function setIsProtocolPaused(bool value) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(value));
    }

    /**
     * @dev see ILTV.setLendingConnector
     */
    function setLendingConnector(address _lendingConnector, bytes memory lendingConnectorData) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(_lendingConnector, lendingConnectorData));
    }

    /**
     * @dev see ILTV.setOracleConnector
     */
    function setOracleConnector(address _oracleConnector, bytes memory oracleConnectorData) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(_oracleConnector, oracleConnectorData));
    }

    /**
     * @dev see ILTV.deleverageAndWithdraw
     */
    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external
    {
        _delegate(
            address(MODULES.administrationModule()),
            abi.encode(closeAmountBorrow, deleverageFeeDividend, deleverageFeeDivider)
        );
    }

    /**
     * @dev see ILTV.softLiquidation
     */
    function softLiquidation(uint256 liquidationAmountBorrow) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(liquidationAmountBorrow));
    }

    /**
     * @dev see ILTV.updateEmergencyDeleverager
     */
    function updateEmergencyDeleverager(address newEmergencyDeleverager) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(newEmergencyDeleverager));
    }

    /**
     * @dev see ILTV.updateGuardian
     */
    function updateGuardian(address newGuardian) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(newGuardian));
    }

    /**
     * @dev see ILTV.updateGovernor
     */
    function updateGovernor(address newGovernor) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(newGovernor));
    }

    /**
     * @dev see ILTV.setMaxGrowthFee
     */
    function setMaxGrowthFee(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setVaultBalanceAsLendingConnector
     */
    function setVaultBalanceAsLendingConnector(
        address _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) external {
        _delegate(
            address(MODULES.administrationModule()),
            abi.encode(_vaultBalanceAsLendingConnector, vaultBalanceAsLendingConnectorGetterData)
        );
    }

    /**
     * @dev see ILTV.setSoftLiquidationFee
     */
    function setSoftLiquidationFee(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }

    /**
     * @dev see ILTV.setSoftLiquidationLtv
     */
    function setSoftLiquidationLtv(uint16 dividend, uint16 divider) external {
        _delegate(address(MODULES.administrationModule()), abi.encode(dividend, divider));
    }
}
