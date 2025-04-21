// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../../Constants.sol';
import '../../../Structs2.sol';
import '../../../utils/MulDiv.sol';
import '../../../math2/CommonMath.sol';
abstract contract TotalAssets {
    using uMulDiv for uint256;

    function totalAssets(TotalAssetsState memory state) public virtual pure returns (uint256) {
        // default behavior - don't overestimate our assets
        return totalAssets(false, state);
    }

    function totalAssets(bool isDeposit, TotalAssetsState memory state) public virtual pure returns (uint256) {
        return _totalAssets(isDeposit, totalAssetsStateToData(state, isDeposit));
    }

    function _totalAssets(bool isDeposit, TotalAssetsData memory data) public pure returns (uint256) {
        // Add 1 to avoid vault attack
        // in case of deposit need to overestimate our assets
        return uint256(data.collateral - data.borrow).mulDiv(Constants.ORACLE_DIVIDER, data.borrowPrice, isDeposit) + 1;
    }

    function totalAssetsStateToData(TotalAssetsState memory state, bool isDeposit) internal pure returns (TotalAssetsData memory) {
        TotalAssetsData memory data;
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

        data.collateral = int256(realCollateral) + futureCollateral + futureRewardCollateral;
        data.borrow = int256(realBorrow) + futureBorrow + futureRewardBorrow;
        data.borrowPrice = state.borrowPrice;

        return data;
    }
}
