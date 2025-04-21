// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../../Constants.sol';
import '../../../Structs2.sol';
import '../../../utils/MulDiv.sol';
import '../../../math2/CommonMath.sol';
import '../borrow/TotalAssets.sol';

abstract contract TotalAssetsCollateral is TotalAssets {
    using uMulDiv for uint256;

    function totalAssetsCollateral(TotalAssetsCollateralState memory state) public pure returns (uint256) {
        // default behavior - don't overestimate our assets
        return totalAssetsCollateral(false, state);
    }

    function totalAssetsCollateral(bool isDeposit, TotalAssetsCollateralState memory state) public pure returns (uint256) {
        return _totalAssetsCollateral(isDeposit, totalAssetsCollateralStateToData(state, isDeposit));
    }

    function _totalAssetsCollateral(bool isDeposit, TotalAssetsCollateralData memory data) public pure returns (uint256) {
        return data.totalAssets.mulDiv(data.borrowPrice, data.collateralPrice, isDeposit);
    }

    function totalAssetsCollateralStateToData(
        TotalAssetsCollateralState memory state,
        bool isDeposit
    ) internal pure returns (TotalAssetsCollateralData memory) {
        TotalAssetsCollateralData memory data;
        uint256 realCollateral = CommonMath.convertRealCollateral(state.realCollateralAssets, state.collateralPrice, isDeposit);
        uint256 realBorrow = CommonMath.convertRealBorrow(state.realBorrowAssets, state.borrowPrice, isDeposit);
        int256 futureCollateral = CommonMath.convertFutureCollateral(state.futureCollateralAssets, state.collateralPrice, isDeposit);
        int256 futureBorrow = CommonMath.convertFutureBorrow(state.futureBorrowAssets, state.borrowPrice, isDeposit);
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.futureRewardCollateralAssets,
            state.collateralPrice,
            isDeposit
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(state.futureRewardBorrowAssets, state.borrowPrice, isDeposit);

        int256 collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        int256 borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;

        data.totalAssets = _totalAssets(isDeposit, TotalAssetsData({collateral: collateral, borrow: borrow, borrowPrice: state.borrowPrice}));
        data.collateralPrice = state.collateralPrice;
        data.borrowPrice = state.borrowPrice;

        return data;
    }
}
