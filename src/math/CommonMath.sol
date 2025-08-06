// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "../utils/MulDiv.sol";

library CommonMath {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function convertRealCollateral(uint256 realCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (uint256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return realCollateralAssets.mulDiv(collateralPrice, Constants.ORACLE_DIVIDER, isDeposit);
    }

    function convertRealBorrow(uint256 realBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (uint256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return realBorrowAssets.mulDiv(borrowPrice, Constants.ORACLE_DIVIDER, !isDeposit);
    }

    function convertFutureCollateral(int256 futureCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return futureCollateralAssets.mulDiv(int256(collateralPrice), int256(Constants.ORACLE_DIVIDER), isDeposit);
    }

    function convertFutureBorrow(int256 futureBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return futureBorrowAssets.mulDiv(int256(borrowPrice), int256(Constants.ORACLE_DIVIDER), !isDeposit);
    }

    function convertFutureRewardCollateral(int256 futureRewardCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return futureRewardCollateralAssets.mulDiv(int256(collateralPrice), int256(Constants.ORACLE_DIVIDER), isDeposit);
    }

    function convertFutureRewardBorrow(int256 futureRewardBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return futureRewardBorrowAssets.mulDiv(int256(borrowPrice), int256(Constants.ORACLE_DIVIDER), !isDeposit);
    }

    function calculateAuctionStep(uint56 startAuction, uint56 blockNumber, uint24 auctionDuration)
        internal
        pure
        returns (uint24)
    {
        uint56 auctionStep = blockNumber - startAuction;

        bool stuck = auctionStep > auctionDuration;

        if (stuck) {
            return auctionDuration;
        }

        return uint24(auctionStep);
    }

    // Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
    function calculateUserFutureRewardBorrow(
        int256 futureRewardBorrowAssets,
        uint256 auctionStep,
        uint24 auctionDuration
    ) internal pure returns (int256) {
        return futureRewardBorrowAssets.mulDivUp(int256(auctionStep), int256(uint256(auctionDuration)));
    }

    // Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
    function calculateUserFutureRewardCollateral(
        int256 futureRewardCollateralAssets,
        uint256 auctionStep,
        uint24 auctionDuration
    ) internal pure returns (int256) {
        return futureRewardCollateralAssets.mulDivDown(int256(auctionStep), int256(uint256(auctionDuration)));
    }
}
