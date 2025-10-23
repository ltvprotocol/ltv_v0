// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IAdministrationErrors
 * @notice Interface defining all custom errors used in the LTV vault administration system
 * @dev This interface contains error definitions for various administrative operations,
 *      access control, configuration validation, and system state checks.
 * @author LTV Protocol
 */
interface IAdministrationErrors {
    /**
     * @notice Error thrown when LTV (Loan-to-Value) parameters are set to invalid values
     * @param targetLtvDividend The numerator of the target LTV ratio
     * @param targetLtvDivider The denominator of the target LTV ratio
     * @param maxSafeLtvDividend The numerator of the maximum safe LTV ratio
     * @param maxSafeLtvDivider The denominator of the maximum safe LTV ratio
     * @param minProfitLtvDividend The numerator of the minimum profit LTV ratio
     * @param minProfitLtvDivider The denominator of the minimum profit LTV ratio
     * @param softLiquidationLtvDividend The numerator of the soft liquidation ltv ratio
     * @param softLiquidationLtvDivider The denominator of the soft liquidation ltv ratio
     * @dev This error occurs when LTV parameters don't satisfy the required relationships
     *      (e.g., target LTV should be between min profit and max safe LTV)
     */
    error InvalidLTVSet(
        uint16 targetLtvDividend,
        uint16 targetLtvDivider,
        uint16 maxSafeLtvDividend,
        uint16 maxSafeLtvDivider,
        uint16 minProfitLtvDividend,
        uint16 minProfitLtvDivider,
        uint16 softLiquidationLtvDividend,
        uint16 softLiquidationLtvDivider
    );

    /**
     * @notice Error thrown when maxSafeLtv is set to an unexpected value
     * @param maxSafeLtvDividend The numerator of the max safe LTV ratio
     * @param maxSafeLtvDivider The denominator of the max safe LTV ratio
     * @dev Used when the max safe LTV doesn't meet expected constraints
     */
    error UnexpectedmaxSafeLtv(uint16 maxSafeLtvDividend, uint16 maxSafeLtvDivider);

    /**
     * @notice Error thrown when minProfitLtv is set to an unexpected value
     * @param minProfitLtvDividend The numerator of the min profit LTV ratio
     * @param minProfitLtvDivider The denominator of the min profit LTV ratio
     * @dev Used when the min profit LTV doesn't meet expected constraints
     */
    error UnexpectedminProfitLtv(uint16 minProfitLtvDividend, uint16 minProfitLtvDivider);

    /**
     * @notice Error thrown when targetLtv is set to an unexpected value
     * @param targetLtvDividend The numerator of the target LTV ratio
     * @param targetLtvDivider The denominator of the target LTV ratio
     * @dev Used when the target LTV doesn't meet expected constraints
     */
    error UnexpectedtargetLtv(uint16 targetLtvDividend, uint16 targetLtvDivider);

    /**
     * @notice Error thrown when attempting to set a zero address as fee collector
     * @dev Prevents setting invalid fee collection addresses
     */
    error ZeroFeeCollector();

    /**
     * @notice Error thrown when deleverage operation cannot cover the required amount
     * @param realBorrowAssets The actual borrowed assets that need to be covered
     * @param providedAssets The assets provided for deleveraging
     * @dev Occurs when provided assets are insufficient to cover the deleverage requirement
     */
    error ImpossibleToCoverDeleverage(uint256 realBorrowAssets, uint256 providedAssets);

    /**
     * @notice Error thrown when maxDeleverageFee parameters are invalid
     * @param maxDeleverageFeeDividend The numerator of the max deleverage fee ratio
     * @param maxDeleverageFeeDivider The denominator of the max deleverage fee ratio
     * @dev Used when deleverage fee parameters don't meet expected constraints
     */
    error InvalidMaxDeleverageFee(uint16 maxDeleverageFeeDividend, uint16 maxDeleverageFeeDivider);

    /**
     * @notice Error thrown when deleverage fee exceeds the maximum allowed
     * @param deleverageFeeDividend The numerator of the current deleverage fee ratio
     * @param deleverageFeeDivider The denominator of the current deleverage fee ratio
     * @param maxDeleverageFeeDividend The numerator of the max allowed deleverage fee ratio
     * @param maxDeleverageFeeDivider The denominator of the max allowed deleverage fee ratio
     * @dev Prevents excessive deleverage fees from being applied
     */
    error ExceedsMaxDeleverageFee(
        uint16 deleverageFeeDividend,
        uint16 deleverageFeeDivider,
        uint16 maxDeleverageFeeDividend,
        uint16 maxDeleverageFeeDivider
    );

    /**
     * @notice Error thrown when attempting to deleverage a vault that is already deleveraged
     * @dev Prevents redundant deleverage operations
     */
    error VaultAlreadyDeleveraged();

    /**
     * @notice Error thrown when maxGrowthFee parameters are invalid
     * @param maxGrowthFeeDividend The numerator of the max growth fee ratio
     * @param maxGrowthFeeDivider The denominator of the max growth fee ratio
     * @dev Used when growth fee parameters don't meet expected constraints
     */
    error InvalidMaxGrowthFee(uint16 maxGrowthFeeDividend, uint16 maxGrowthFeeDivider);

    /**
     * @notice Error thrown when a function is called by an account that is not an emergency deleverager
     * @param account The address of the unauthorized caller
     * @dev Access control error for emergency deleveraging functions
     */
    error OnlyEmergencyDeleveragerInvalidCaller(address account);

    /**
     * @notice Error thrown when a function is called by an account that is not a governor
     * @param account The address of the unauthorized caller
     * @dev Access control error for governance functions
     */
    error OnlyGovernorInvalidCaller(address account);

    /**
     * @notice Error thrown when a function is called by an account that is not a guardian
     * @param account The address of the unauthorized caller
     * @dev Access control error for guardian-only functions
     */
    error OnlyGuardianInvalidCaller(address account);

    /**
     * @notice Error thrown when deposit functionality is disabled
     * @dev Used when the vault is in a state where deposits are not allowed
     */
    error DepositIsDisabled();

    /**
     * @notice Error thrown when withdraw functionality is disabled
     * @dev Used when the vault is in a state where withdrawals are not allowed
     */
    error WithdrawIsDisabled();

    /**
     * @notice Error thrown when a specific function is stopped/disabled
     * @param functionSignature The 4-byte function selector that is disabled
     * @dev Used for emergency function disabling
     */
    error FunctionStopped(bytes4 functionSignature);

    /**
     * @notice Error thrown when the protocol is paused
     * @dev Used when the protocol is in a state where it is paused
     */
    error ProtocolIsPaused();

    /**
     * @notice Error thrown when attempting to send assets to a non-whitelisted receiver
     * @param receiver The address of the non-whitelisted receiver
     * @dev Prevents unauthorized asset transfers
     */
    error ReceiverNotWhitelisted(address receiver);

    /**
     * @notice Error thrown when whitelist registry is not configured
     * @dev Occurs when trying to use whitelist functionality without proper setup
     */
    error WhitelistRegistryNotSet();

    /**
     * @notice Error thrown when whitelist is already activated
     * @dev Prevents duplicate whitelist activation
     */
    error WhitelistIsActivated();

    /**
     * @notice Error thrown when attempting to set a zero address as slippage connector
     * @dev Prevents setting invalid slippage connector addresses
     */
    error ZeroSlippageConnector();
    error EOADelegateCall();

    /**
     * @notice Error thrown when vault balance as lending connector is not configured
     * @dev Occurs when trying to use lending connector functionality without proper setup
     */
    error VaultBalanceAsLendingConnectorNotSet();

    /**
     * @notice Error thrown when attempting to set a zero address as modules provider
     * @dev Prevents setting invalid modules provider addresses
     */
    error ZeroModulesProvider();

    /**
     * @notice Error thrown when setting lending connector fails
     * @param lendingConnector The address of the lending connector that failed to set
     * @param lendingConnectorData The data used for setting the lending connector
     * @dev Used when configuration of lending connector encounters an error
     */
    error FailedToSetLendingConnector(address lendingConnector, bytes lendingConnectorData);

    /**
     * @notice Error thrown when setting oracle connector fails
     * @param oracleConnector The address of the oracle connector that failed to set
     * @param oracleConnectorData The data used for setting the oracle connector
     * @dev Used when configuration of oracle connector encounters an error
     */
    error FailedToSetOracleConnector(address oracleConnector, bytes oracleConnectorData);

    /**
     * @notice Error thrown when setting slippage connector fails
     * @param slippageConnector The address of the slippage connector that failed to set
     * @param slippageConnectorData The data used for setting the slippage connector
     * @dev Used when configuration of slippage connector encounters an error
     */
    error FailedToSetSlippageConnector(address slippageConnector, bytes slippageConnectorData);

    /**
     * @notice Error thrown when setting vault balance as lending connector fails
     * @param vaultBalanceAsLendingConnector The address of the vault balance connector that failed to set
     * @param vaultBalanceAsLendingConnectorGetterData The data used for setting the vault balance connector
     * @dev Used when configuration of vault balance as lending connector encounters an error
     */
    error FailedToSetVaultBalanceAsLendingConnector(
        address vaultBalanceAsLendingConnector, bytes vaultBalanceAsLendingConnectorGetterData
    );

    /**
     * @notice Error thrown when soft liquidation expected result is below configured threshold
     * @param calculatedBorrowInUnderlying Expected borrow assets amount in lending protocol after liquidation
     * @param calculatedCollateralInUnderlying Expected collateral assets amount in lending protocol after liquidation
     * @param softLiquidationLtvDividend The dividend of the soft liquidation ltv
     * @param softLiquidationLtvDivider The divider of the soft liquidation ltv
     * @dev Used when soft liquidation result is below soft liquidation ltv
     */
    error SoftLiquidationResultBelowSoftLiquidationLtv(
        uint256 calculatedBorrowInUnderlying,
        uint256 calculatedCollateralInUnderlying,
        uint16 softLiquidationLtvDividend,
        uint16 softLiquidationLtvDivider
    );

    /**
     * @notice Error thrown when soft liquidation fee parameters are invalid
     * @param softLiquidationFeeDividend The numerator of the soft liquidation fee ratio
     * @param softLiquidationFeeDivider The denominator of the soft liquidation fee ratio
     * @dev Used when soft liquidation fee parameters don't meet expected constraints
     */
    error InvalidSoftLiquidationFee(uint16 softLiquidationFeeDividend, uint16 softLiquidationFeeDivider);

    /**
     * @notice Error thrown when soft liquidation ltv parameters are invalid
     * @param softLiquidationLtvDividend The numerator of the soft liquidation ltv ratio
     * @param softLiquidationLtvDivider The denominator of the soft liquidation ltv ratio
     * @dev Used when soft liquidation ltv parameters don't meet expected constraints
     */
    error InvalidSoftLiquidationLtv(uint16 softLiquidationLtvDividend, uint16 softLiquidationLtvDivider);

    /**
     * @notice Error thrown when soft liquidation fee is too high
     * @dev Possible in a case of very high soft liquidation fee, which leads to a situation where
     * soft liquidation only making ltv worse.
     */
    error SoftLiquidationFeeTooHigh();
}
