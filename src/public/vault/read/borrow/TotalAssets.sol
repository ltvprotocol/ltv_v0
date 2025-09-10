// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

abstract contract TotalAssets {
    using UMulDiv for uint256;

    function totalAssets(TotalAssetsState memory state) public pure virtual returns (uint256) {
        // default behavior - don't overestimate our assets
        return totalAssets(false, state);
    }

    function totalAssets(bool isDeposit, TotalAssetsState memory state) public pure virtual returns (uint256) {
        return _totalAssets(isDeposit, totalAssetsStateToData(state, isDeposit));
    }

    function _totalAssets(bool isDeposit, TotalAssetsData memory data) internal pure virtual returns (uint256) {
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

        // casting to int256 is safe because realCollateral is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        // casting to int256 is safe because realBorrow is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        data.borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.commonTotalAssetsState.borrowPrice;

        return data;
    }
}
