// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsState} from "../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsCollateralData} from "../../../structs/data/vault/total_assets/TotalAssetsCollateralData.sol";
import {TotalAssetsData} from "../../../structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssets} from "../../../public/vault/read/borrow/TotalAssets.sol";
import {CommonMath} from "../../libraries/CommonMath.sol";

abstract contract TotalAssetsCollateralStateToData is TotalAssets {
    /**
     * @dev base function to calculate total assets collateral state to data
     */
    function totalAssetsStateToTotalAssetsCollateralData(TotalAssetsState memory state, bool isDeposit)
        internal
        pure
        returns (TotalAssetsCollateralData memory)
    {
        TotalAssetsCollateralData memory data;
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

        // casting to int256 is safe because realCollateral and
        // realBorrow are considered to be smaller than type(int256).max
        // forge-lint: disable-start(unsafe-typecast)
        int256 collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        int256 borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;
        // forge-lint: disable-end(unsafe-typecast)

        data.totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({
                collateral: collateral,
                borrow: borrow,
                borrowPrice: state.commonTotalAssetsState.borrowPrice,
                borrowTokenDecimals: state.commonTotalAssetsState.borrowTokenDecimals
            })
        );
        data.collateralPrice = state.commonTotalAssetsState.collateralPrice;
        data.borrowPrice = state.commonTotalAssetsState.borrowPrice;
        data.borrowTokenDecimals = state.commonTotalAssetsState.borrowTokenDecimals;
        data.collateralTokenDecimals = state.commonTotalAssetsState.collateralTokenDecimals;

        return data;
    }
}
