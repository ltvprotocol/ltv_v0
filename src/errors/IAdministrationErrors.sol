// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAdministrationErrors {
    error InvalidLTVSet(uint128 targetLTV, uint128 maxSafeLTV, uint128 minProfitLTV);
    error UnexpectedMaxSafeLTV(uint128 maxSafeLTV);
    error UnexpectedMinProfitLTV(uint128 minProfitLTV);
    error UnexpectedTargetLTV(uint128 targetLTV);
    error ZeroFeeCollector();
    error ImpossibleToCoverDeleverage(uint256 realBorrowAssets, uint256 providedAssets);
    error InvalidMaxDeleverageFee(uint256 deleverageFee);
    error ExceedsMaxDeleverageFee(uint256 deleverageFee, uint256 maxDeleverageFee);
    error VaultAlreadyDeleveraged();
    error InvalidMaxGrowthFee(uint256 maxGrowthFee);
    error OnlyEmergencyDeleveragerInvalidCaller(address account);
    error OnlyGovernorInvalidCaller(address account);
    error OnlyGuardianInvalidCaller(address account);
    error DepositIsDisabled();
    error WithdrawIsDisabled();
    error FunctionStopped(bytes4 functionSignature);
    error ReceiverNotWhitelisted(address receiver);
    error WhitelistRegistryNotSet();
    error WhitelistIsActivated();
}
