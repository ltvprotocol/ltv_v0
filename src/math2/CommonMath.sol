// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../utils/MulDiv.sol';

library CommonMath {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function convertRealCollateral(uint256 realCollateralAssets, uint256 collateralPrice, bool isDeposit) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return realCollateralAssets.mulDiv(collateralPrice, Constants.ORACLE_DIVIDER, isDeposit);
    }

    function convertRealBorrow(uint256 realBorrowAssets, uint256 borrowPrice, bool isDeposit) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return realBorrowAssets.mulDiv(borrowPrice, Constants.ORACLE_DIVIDER, !isDeposit);
    }

    function convertFutureCollateral(uint256 futureCollateralAssets, uint256 collateralPrice, bool isDeposit) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return futureCollateralAssets.mulDiv(collateralPrice, Constants.ORACLE_DIVIDER, isDeposit);
    }

    function convertFutureBorrow(uint256 futureBorrowAssets, uint256 borrowPrice, bool isDeposit) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return futureBorrowAssets.mulDiv(borrowPrice, Constants.ORACLE_DIVIDER, !isDeposit);
    }

    function convertFutureRewardCollateral(
        uint256 futureRewardCollateralAssets,
        uint256 collateralPrice,
        bool isDeposit
    ) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return futureRewardCollateralAssets.mulDiv(collateralPrice, Constants.ORACLE_DIVIDER, isDeposit);
    }

    function convertFutureRewardBorrow(uint256 futureRewardBorrowAssets, uint256 borrowPrice, bool isDeposit) internal pure returns (uint256) {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return futureRewardBorrowAssets.mulDiv(borrowPrice, Constants.ORACLE_DIVIDER, !isDeposit);
    }
}
