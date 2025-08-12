// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAdministrationEvents {
    event EmergencyDeleveragerUpdated(address oldValue, address newValue);
    event GuardianUpdated(address oldValue, address newValue);
    event GovernorUpdated(address oldValue, address newValue);

    event TargetLTVChanged(uint128 oldValue, uint128 newValue);
    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);

    event WhitelistRegistryUpdated(address oldValue, address newValue);
    event MaxTotalAssetsInUnderlyingChanged(uint256 oldValue, uint256 newValue);
    event MaxDeleverageFeeChanged(uint256 oldValue, uint256 newValue);
    event MaxGrowthFeeChanged(uint256 oldValue, uint256 newValue);
    event IsWhitelistActivatedChanged(bool oldValue, bool newValue);
    event IsDepositDisabledChanged(bool oldValue, bool newValue);
    event IsWithdrawDisabledChanged(bool oldValue, bool newValue);
    event LendingConnectorUpdated(
        address oldValue, bytes oldLendingConnectorData, address newValue, bytes newLendingConnectorData
    );
    event OracleConnectorUpdated(
        address oldValue, bytes oldOracleConnectorData, address newValue, bytes newOracleConnectorData
    );
    event SlippageProviderUpdated(
        address oldValue, bytes oldSlippageProviderData, address newValue, bytes newSlippageProviderData
    );
    event FeeCollectorUpdated(address oldValue, address newValue);
    event ModulesUpdated(address oldValue, address newValue);
    event VaultBalanceAsLendingConnectorUpdated(address oldValue, address newValue);
}
