// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAdministrationErrors {
    error InvalidLTVSet(
        uint24 targetLTVDividend,
        uint24 targetLTVDivider,
        uint24 maxSafeLTVDividend,
        uint24 maxSafeLTVDivider,
        uint24 minProfitLTVDividend,
        uint24 minProfitLTVDivider
    );
    error UnexpectedMaxSafeLTV(uint24 maxSafeLTVDividend, uint24 maxSafeLTVDivider);
    error UnexpectedMinProfitLTV(uint24 minProfitLTVDividend, uint24 minProfitLTVDivider);
    error UnexpectedTargetLTV(uint24 targetLTVDividend, uint24 targetLTVDivider);
    error ZeroFeeCollector();
    error ImpossibleToCoverDeleverage(uint256 realBorrowAssets, uint256 providedAssets);
    error InvalidMaxDeleverageFee(uint16 maxDeleverageFeeDividend, uint16 maxDeleverageFeeDivider);
    error ExceedsMaxDeleverageFee(
        uint16 deleverageFeeDividend,
        uint16 deleverageFeeDivider,
        uint16 maxDeleverageFeeDividend,
        uint16 maxDeleverageFeeDivider
    );
    error VaultAlreadyDeleveraged();
    error InvalidMaxGrowthFee(uint16 maxGrowthFeeDividend, uint16 maxGrowthFeeDivider);
    error OnlyEmergencyDeleveragerInvalidCaller(address account);
    error OnlyGovernorInvalidCaller(address account);
    error OnlyGuardianInvalidCaller(address account);
    error DepositIsDisabled();
    error WithdrawIsDisabled();
    error FunctionStopped(bytes4 functionSignature);
    error ReceiverNotWhitelisted(address receiver);
    error WhitelistRegistryNotSet();
    error WhitelistIsActivated();
    error ZeroSlippageProvider();
    error EOADelegateCall();
    error VaultBalanceAsLendingConnectorNotSet();
    error ZeroModulesProvider();
}
