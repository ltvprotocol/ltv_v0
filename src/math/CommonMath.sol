// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {uMulDiv, sMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title CommonMath
 * @notice This library contains functions to precalculate state before vault operations.
 */
library CommonMath {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    /**
     * @notice This function converts real collateral amount from collateral asset to underlying asset.
     */
    function convertRealCollateral(uint256 realCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (uint256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        return realCollateralAssets.mulDiv(collateralPrice, Constants.ORACLE_DIVIDER, isDeposit);
    }

    /**
     * @notice This function converts real borrow amount from borrow asset to underlying asset.
     */
    function convertRealBorrow(uint256 realBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (uint256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        return realBorrowAssets.mulDiv(borrowPrice, Constants.ORACLE_DIVIDER, !isDeposit);
    }

    /**
     * @notice This function converts future collateral amount from collateral asset to underlying asset.
     */
    function convertFutureCollateral(int256 futureCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        // casting to int256 is safe because collateralPrice is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureCollateralAssets.mulDiv(int256(collateralPrice), int256(Constants.ORACLE_DIVIDER), isDeposit);
    }

    /**
     * @notice This function converts future borrow amount from borrow asset to underlying asset.
     */
    function convertFutureBorrow(int256 futureBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        // casting to int256 is safe because borrowPrice is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureBorrowAssets.mulDiv(int256(borrowPrice), int256(Constants.ORACLE_DIVIDER), !isDeposit);
    }

    /**
     * @notice This function converts future reward collateral amount from collateral asset to underlying asset.
     */
    function convertFutureRewardCollateral(int256 futureRewardCollateralAssets, uint256 collateralPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        // casting to int256 is safe because collateralPrice is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureRewardCollateralAssets.mulDiv(int256(collateralPrice), int256(Constants.ORACLE_DIVIDER), isDeposit);
    }

    /**
     * @notice This function converts future reward borrow amount from borrow asset to underlying asset.
     */
    function convertFutureRewardBorrow(int256 futureRewardBorrowAssets, uint256 borrowPrice, bool isDeposit)
        internal
        pure
        returns (int256)
    {
        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        // casting to int256 is safe because borrowPrice is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureRewardBorrowAssets.mulDiv(int256(borrowPrice), int256(Constants.ORACLE_DIVIDER), !isDeposit);
    }

    /**
     * @notice This function calculates auction step using start auction and block number.
     */
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

        // casting to uint24 is safe because auctionStep is considered to be smaller or equal to auction duration
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint24(auctionStep);
    }

    /**
     * @notice This function calculates user future reward borrow using future reward borrow assets,
     *  auction step and auction duration.
     *
     * ROUNDING:
     * Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
     */
    function calculateUserFutureRewardBorrow(
        int256 futureRewardBorrowAssets,
        uint256 auctionStep,
        uint24 auctionDuration
    ) internal pure returns (int256) {
        // casting to int256 is safe because futureRewardBorrowAssets is considered to be smaller than type(int256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureRewardBorrowAssets.mulDivUp(int256(auctionStep), int256(uint256(auctionDuration)));
    }

    /**
     * @notice This function calculates user future reward collateral using future reward collateral assets,
     *  auction step and auction duration.
     *
     * ROUNDING:
     * Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
     */
    function calculateUserFutureRewardCollateral(
        int256 futureRewardCollateralAssets,
        uint256 auctionStep,
        uint24 auctionDuration
    ) internal pure returns (int256) {
        // casting to int256 is safe because auction step is considered to be smaller than type(int256).max,
        // and uint24 is smaller than type(uint256).max
        // forge-lint: disable-next-line(unsafe-typecast)
        return futureRewardCollateralAssets.mulDivDown(int256(auctionStep), int256(uint256(auctionDuration)));
    }
}
