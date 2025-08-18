// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {TotalAssetsData} from "src/structs/data/vault/TotalAssetsData.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {TotalAssetsCollateralData} from "src/structs/data/vault/TotalAssetsCollateralData.sol";
import {TotalAssets} from "src/public/vault/borrow/TotalAssets.sol";
import {CommonMath} from "src/math/CommonMath.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract TotalAssetsCollateral is TotalAssets {
    using uMulDiv for uint256;

    function totalAssetsCollateral(TotalAssetsState memory state) public pure virtual returns (uint256) {
        // default behavior - don't overestimate our assets
        return totalAssetsCollateral(false, state);
    }

    function totalAssetsCollateral(bool isDeposit, TotalAssetsState memory state)
        public
        pure
        virtual
        returns (uint256)
    {
        return _totalAssetsCollateral(isDeposit, totalAssetsStateToTotalAssetsCollateralData(state, isDeposit));
    }

    function _totalAssetsCollateral(bool isDeposit, TotalAssetsCollateralData memory data)
        public
        pure
        returns (uint256)
    {
        return data.totalAssets.mulDiv(data.borrowPrice, data.collateralPrice, isDeposit);
    }

    function totalAssetsStateToTotalAssetsCollateralData(TotalAssetsState memory state, bool isDeposit)
        internal
        pure
        returns (TotalAssetsCollateralData memory)
    {
        TotalAssetsCollateralData memory data;
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

        int256 collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        int256 borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;

        data.totalAssets = _totalAssets(
            isDeposit,
            TotalAssetsData({
                collateral: collateral,
                borrow: borrow,
                borrowPrice: state.commonTotalAssetsState.borrowPrice
            })
        );
        data.collateralPrice = state.commonTotalAssetsState.collateralPrice;
        data.borrowPrice = state.commonTotalAssetsState.borrowPrice;

        return data;
    }
}
