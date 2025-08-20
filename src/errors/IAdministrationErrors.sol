// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAdministrationErrors {
    error InvalidLTVSet(
        uint24 targetLtvDividend,
        uint24 targetLtvDivider,
        uint24 maxSafeLtvDividend,
        uint24 maxSafeLtvDivider,
        uint24 minProfitLtvDividend,
        uint24 minProfitLtvDivider
    );
    error UnexpectedmaxSafeLtv(uint24 maxSafeLtvDividend, uint24 maxSafeLtvDivider);
    error UnexpectedminProfitLtv(uint24 minProfitLtvDividend, uint24 minProfitLtvDivider);
    error UnexpectedtargetLtv(uint24 targetLtvDividend, uint24 targetLtvDivider);
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
