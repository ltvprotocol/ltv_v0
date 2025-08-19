// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {TotalAssetsData} from "src/structs/data/vault/TotalAssetsData.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {CommonMath} from "src/math/CommonMath.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract TotalAssets {
    using uMulDiv for uint256;

    function totalAssets(TotalAssetsState memory state) public pure virtual returns (uint256) {
        // default behavior - don't overestimate our assets
        return totalAssets(false, state);
    }

    function totalAssets(bool isDeposit, TotalAssetsState memory state) public pure virtual returns (uint256) {
        return _totalAssets(isDeposit, totalAssetsStateToData(state, isDeposit));
    }

    function _totalAssets(bool isDeposit, TotalAssetsData memory data) public pure virtual returns (uint256) {
        // Add 100 to avoid vault attack
        // in case of deposit need to overestimate our assets
        return uint256(data.collateral - data.borrow).mulDiv(Constants.ORACLE_DIVIDER, data.borrowPrice, isDeposit)
            + Constants.VIRTUAL_ASSETS_AMOUNT;
    }

    function totalAssetsStateToData(TotalAssetsState memory state, bool isDeposit)
        internal
        pure
        returns (TotalAssetsData memory)
    {
        TotalAssetsData memory data;
        uint256 realCollateral = CommonMath.convertRealCollateral(
            state.realCollateralAssets, state.commonTotalAssetsState.collateralPrice, isDeposit
        );
        uint256 realBorrow =
            CommonMath.convertRealBorrow(state.realBorrowAssets, state.commonTotalAssetsState.borrowPrice, isDeposit);
        int256 futureCollateral = CommonMath.convertFutureCollateral(
            state.commonTotalAssetsState.futureCollateralAssets, state.commonTotalAssetsState.collateralPrice, isDeposit
        );
        int256 futureBorrow = CommonMath.convertFutureBorrow(
            state.commonTotalAssetsState.futureBorrowAssets, state.commonTotalAssetsState.borrowPrice, isDeposit
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.commonTotalAssetsState.futureRewardCollateralAssets,
            state.commonTotalAssetsState.collateralPrice,
            isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.commonTotalAssetsState.futureRewardBorrowAssets, state.commonTotalAssetsState.borrowPrice, isDeposit
        );

        data.collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.commonTotalAssetsState.borrowPrice;

        return data;
    }
}
