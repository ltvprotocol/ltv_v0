// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAdministrationEvents
 * @notice Interface defining all events emitted during administrative operations in the LTV vault system
 * @dev This interface contains event definitions for various administrative changes including
 *      access control updates, parameter modifications, connector updates, and system configuration changes.
 *      These events provide transparency and allow external systems to track administrative actions.
 * @author LTV Protocol
 */
interface IAdministrationEvents {
    /**
     * @notice Emitted when the emergency deleverager address is updated
     * @param oldValue The previous emergency deleverager address
     * @param newValue The new emergency deleverager address
     * @dev Emergency deleverager has special permissions to deleverage vaults in emergency situations
     */
    event EmergencyDeleveragerUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the guardian address is updated
     * @param oldValue The previous guardian address
     * @param newValue The new guardian address
     * @dev Guardian has permissions to perform emergency operations and pause functionality
     */
    event GuardianUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the governor address is updated
     * @param oldValue The previous governor address
     * @param newValue The new governor address
     * @dev Governor has permissions to update system parameters and perform administrative functions
     */
    event GovernorUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the target LTV (Loan-to-Value) ratio is changed
     * @param oldDividend The previous target LTV numerator
     * @param oldDivider The previous target LTV denominator
     * @param newDividend The new target LTV numerator
     * @param newDivider The new target LTV denominator
     * @dev Target LTV represents the optimal borrowing ratio the vault aims to maintain
     */
    event TargetLtvChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the maximum safe LTV ratio is changed
     * @param oldDividend The previous max safe LTV numerator
     * @param oldDivider The previous max safe LTV denominator
     * @param newDividend The new max safe LTV numerator
     * @param newDivider The new max safe LTV denominator
     * @dev Max safe LTV represents the highest LTV ratio considered safe for the vault
     */
    event MaxSafeLtvChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the minimum profit LTV ratio is changed
     * @param oldDividend The previous min profit LTV numerator
     * @param oldDivider The previous min profit LTV denominator
     * @param newDividend The new min profit LTV numerator
     * @param newDivider The new min profit LTV denominator
     * @dev Min profit LTV represents the lowest LTV ratio where the vault can still generate profits
     */
    event MinProfitLtvChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the whitelist registry address is updated
     * @param oldValue The previous whitelist registry address
     * @param newValue The new whitelist registry address
     * @dev Whitelist registry controls which addresses can interact with the vault
     */
    event WhitelistRegistryUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the maximum total assets in underlying is changed
     * @param oldValue The previous maximum total assets limit
     * @param newValue The new maximum total assets limit
     * @dev This limit controls the maximum amount of assets the vault can hold
     */
    event MaxTotalAssetsInUnderlyingChanged(uint256 oldValue, uint256 newValue);

    /**
     * @notice Emitted when the maximum deleverage fee is changed
     * @param oldDividend The previous max deleverage fee numerator
     * @param oldDivider The previous max deleverage fee denominator
     * @param newDividend The new max deleverage fee numerator
     * @param newDivider The new max deleverage fee denominator
     * @dev Max deleverage fee limits the fee charged during deleveraging operations
     */
    event MaxDeleverageFeeChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the maximum growth fee is changed
     * @param oldDividend The previous max growth fee numerator
     * @param oldDivider The previous max growth fee denominator
     * @param newDividend The new max growth fee numerator
     * @param newDivider The new max growth fee denominator
     * @dev Max growth fee limits the fee charged during vault growth operations
     */
    event MaxGrowthFeeChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the whitelist activation status is changed
     * @param oldValue The previous whitelist activation status
     * @param newValue The new whitelist activation status
     * @dev Controls whether the whitelist functionality is active
     */
    event IsWhitelistActivatedChanged(bool oldValue, bool newValue);

    /**
     * @notice Emitted when the deposit disabled status is changed
     * @param oldValue The previous deposit disabled status
     * @param newValue The new deposit disabled status
     * @dev Controls whether deposits are allowed in the vault
     */
    event IsDepositDisabledChanged(bool oldValue, bool newValue);

    /**
     * @notice Emitted when the withdraw disabled status is changed
     * @param oldValue The previous withdraw disabled status
     * @param newValue The new withdraw disabled status
     * @dev Controls whether withdrawals are allowed from the vault
     */
    event IsWithdrawDisabledChanged(bool oldValue, bool newValue);

    /**
     * @notice Emitted when the protocol paused status is changed
     * @param oldValue The previous protocol paused status
     * @param newValue The new protocol paused status
     * @dev Controls whether the protocol is paused
     */
    event IsProtocolPausedChanged(bool oldValue, bool newValue);

    /**
     * @notice Emitted when the lending connector is updated
     * @param oldValue The previous lending connector address
     * @param oldLendingConnectorData The previous lending connector configuration data
     * @param newValue The new lending connector address
     * @param newLendingConnectorData The new lending connector configuration data
     * @dev Lending connector handles lending and borrowing operations with external protocols
     */
    event LendingConnectorUpdated(
        address oldValue, bytes oldLendingConnectorData, address newValue, bytes newLendingConnectorData
    );

    /**
     * @notice Emitted when the oracle connector is updated
     * @param oldValue The previous oracle connector address
     * @param oldOracleConnectorData The previous oracle connector configuration data
     * @param newValue The new oracle connector address
     * @param newOracleConnectorData The new oracle connector configuration data
     * @dev Oracle connector provides price feeds and market data for the vault
     */
    event OracleConnectorUpdated(
        address oldValue, bytes oldOracleConnectorData, address newValue, bytes newOracleConnectorData
    );

    /**
     * @notice Emitted when the slippage connector is updated
     * @param oldValue The previous slippage connector address
     * @param oldSlippageConnectorData The previous slippage connector configuration data
     * @param newValue The new slippage connector address
     * @param newSlippageConnectorData The new slippage connector configuration data
     */
    event SlippageConnectorUpdated(
        address oldValue, bytes oldSlippageConnectorData, address newValue, bytes newSlippageConnectorData
    );

    /**
     * @notice Emitted when the fee collector address is updated
     * @param oldValue The previous fee collector address
     * @param newValue The new fee collector address
     * @dev Fee collector receives fees generated by the vault operations
     */
    event FeeCollectorUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the modules provider address is updated
     * @param oldValue The previous modules provider address
     * @param newValue The new modules provider address
     * @dev Modules provider supplies additional functionality modules to the vault
     */
    event ModulesUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the vault balance as lending connector is updated
     * @param oldValue The previous vault balance connector address
     * @param newValue The new vault balance connector address
     * @dev This connector helps track vault balances in lending protocols
     */
    event VaultBalanceAsLendingConnectorUpdated(address oldValue, address newValue);

    /**
     * @notice Emitted when the soft liquidation enabled for anyone status is changed
     * @param oldValue The previous soft liquidation enabled for anyone status
     * @param newValue The new soft liquidation enabled for anyone status
     * @dev Controls whether anyone can perform soft liquidation
     */
    event IsSoftLiquidationEnabledForAnyoneChanged(bool oldValue, bool newValue);

    /**
     * @notice Emitted when the soft liquidation fee is changed
     * @param oldDividend The previous soft liquidation fee numerator
     * @param oldDivider The previous soft liquidation fee denominator
     * @param newDividend The new soft liquidation fee numerator
     * @param newDivider The new soft liquidation fee denominator
     * @dev Controls the fee charged during soft liquidation operations
     */
    event SoftLiquidationFeeChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when the soft liquidation ltv is changed
     * @param oldDividend The previous soft liquidation ltv numerator
     * @param oldDivider The previous soft liquidation ltv denominator
     * @param newDividend The new soft liquidation ltv numerator
     * @param newDivider The new soft liquidation ltv denominator
     * @dev Controls the ltv threshold for soft liquidation operations
     */
    event SoftLiquidationLtvChanged(uint16 oldDividend, uint16 oldDivider, uint16 newDividend, uint16 newDivider);

    /**
     * @notice Emitted when a function is paused
     * @param functionSignature The function signature that is paused
     * @param isPaused The new paused status
     * @dev Used for emergency function disabling
     */
    event FunctionPausedChanged(bytes4 functionSignature, bool isPaused);

    /**
     * @notice Emitted when liquidation operation is performed
     * @param liquidationAmountBorrow The amount of borrow repaid
     * @param bonusDividend The bonus fee numerator
     * @param bonusDivider The bonus fee denominator
     * @param isSoftLiquidation The flag indicating if the liquidation is soft
     * @dev Emitted when liquidation operation is performed
     */
    event LiquidationPerformed(
        uint256 liquidationAmountBorrow, uint16 bonusDividend, uint16 bonusDivider, bool isSoftLiquidation
    );

    /**
     * @notice Emitted when the slippage connector data is updated
     * @param oldData The previous slippage connector data
     * @param newData The new slippage connector data
     * @dev Emitted when the slippage connector data is updated
     */
    event SlippageConnectorDataUpdated(bytes oldData, bytes newData);

    /**
     * @notice Emitted when token is transferred from the protocol balance to the owner
     * @param token The token that is transferred
     * @param amount The amount of tokens that is transferred
     * @dev Emitted when token is transferred from the protocol balance to the owner
     */
    event TokenSwept(address token, uint256 amount);
}
