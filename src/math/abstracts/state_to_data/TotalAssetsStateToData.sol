// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsState} from "../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsData} from "../../../structs/data/vault/total_assets/TotalAssetsData.sol";
import {CommonMath} from "../../libraries/CommonMath.sol";

abstract contract TotalAssetsStateToData {
    /**
     * @dev base function to calculate pure total assets state to data needed to calculate total assets
     */
    function totalAssetsStateToData(TotalAssetsState memory state, bool isDeposit)
        internal
        pure
        returns (TotalAssetsData memory)
    {
        TotalAssetsData memory data;
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.realCollateralAssets,
            state.commonTotalAssetsState.collateralPrice,
            state.commonTotalAssetsState.collateralTokenDecimals,
            isDeposit
        );
        uint256 realBorrow = CommonMath.convertRealBorrow(
            state.realBorrowAssets,
            state.commonTotalAssetsState.borrowPrice,
            state.commonTotalAssetsState.borrowTokenDecimals,
            isDeposit
        );
        int256 futureCollateral = CommonMath.convertFutureCollateral(
            state.commonTotalAssetsState.futureCollateralAssets,
            state.commonTotalAssetsState.collateralPrice,
            state.commonTotalAssetsState.collateralTokenDecimals,
            isDeposit
        );
        int256 futureBorrow = CommonMath.convertFutureBorrow(
            state.commonTotalAssetsState.futureBorrowAssets,
            state.commonTotalAssetsState.borrowPrice,
            state.commonTotalAssetsState.borrowTokenDecimals,
            isDeposit
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.commonTotalAssetsState.futureRewardCollateralAssets,
            state.commonTotalAssetsState.collateralPrice,
            state.commonTotalAssetsState.collateralTokenDecimals,
            isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.commonTotalAssetsState.futureRewardBorrowAssets,
            state.commonTotalAssetsState.borrowPrice,
            state.commonTotalAssetsState.borrowTokenDecimals,
            isDeposit
        );

        // casting to int256 is safe because realCollateral is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        // casting to int256 is safe because realBorrow is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.commonTotalAssetsState.borrowPrice;
        data.borrowTokenDecimals = state.commonTotalAssetsState.borrowTokenDecimals;

        return data;
    }
}
