// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract AdministrationErrors {
    error InvalidLTVSet(uint128 targetLTV, uint128 maxSafeLTV, uint128 minProfitLTV);
    error ImpossibleToCoverDeleverage(uint256 realBorrowAssets, uint256 providedAssets);
    error InvalidMaxDeleverageFee(uint256 deleverageFee);
    error ExceedsMaxDeleverageFee(uint256 deleverageFee, uint256 maxDeleverageFee);
    error VaultAlreadyDeleveraged();
    error InvalidMaxGrowthFee(uint256 maxGrowthFee);
}