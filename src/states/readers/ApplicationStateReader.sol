// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../LTVState.sol";
import "../../structs/StateRepresentationStruct.sol";

abstract contract ApplicationStateReader is LTVState {
    function getStateRepresentation() internal view returns (StateRepresentationStruct memory) {
        return StateRepresentationStruct({
            futureBorrowAssets: futureBorrowAssets,
            futureCollateralAssets: futureCollateralAssets,
            futureRewardBorrowAssets: futureRewardBorrowAssets,
            futureRewardCollateralAssets: futureRewardCollateralAssets,
            startAuction: startAuction,
            baseTotalSupply: baseTotalSupply,
            maxSafeLTV: maxSafeLTV,
            minProfitLTV: minProfitLTV,
            targetLTV: targetLTV,
            isVaultDeleveraged: isVaultDeleveraged,
            lastSeenTokenPrice: lastSeenTokenPrice,
            maxGrowthFee: maxGrowthFee,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            isDepositDisabled: isDepositDisabled,
            isWithdrawDisabled: isWithdrawDisabled,
            isWhitelistActivated: isWhitelistActivated,
            maxDeleverageFee: maxDeleverageFee
        });
    }
}
