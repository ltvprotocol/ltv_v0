// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './State.sol';
import './Lending.sol';
import 'forge-std/console.sol';

abstract contract WithdrawAuction is State, Lending {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    error NoWithdrawAuction();
    error BadWithdrawAuctionPreview(int256 deltaUserCollateral, int256 deltaUserBorrow, int256 deltaProtocolFutureRewardCollateralAssets);

    function executeWithdrawAuctionCollateral(uint256 collateral) external returns (uint256) {
        (
            int256 deltaUserBorrow,
            int256 deltaUserCollateral,
            int256 deltaProtocolFutureRewardBorrowAssets
        ) = calculateExecuteWithdrawAuctionCollateral(collateral);

        _executeWithdrawAuction(deltaUserBorrow, deltaUserCollateral, deltaProtocolFutureRewardBorrowAssets);
        return uint256(deltaUserBorrow);
    }

    function executeWithdrawAuctionBorrow(uint256 borrow) external returns (uint256) {
        (int256 deltaUserBorrow, int256 deltaUserCollateral, int256 deltaProtocolFutureRewardBorrowAssets) = calculateExecuteWithdrawAuctionBorrow(
            borrow
        );

        _executeWithdrawAuction(deltaUserBorrow, deltaUserCollateral, deltaProtocolFutureRewardBorrowAssets);
        return uint256(deltaUserCollateral);
    }

    function previewExecuteWithdrawAuctionCollateral(uint256 collateral) external view returns (uint256) {
        (int256 deltaUserBorrow, , ) = calculateExecuteWithdrawAuctionCollateral(collateral);
        return uint256(deltaUserBorrow);
    }

    function previewExecuteWithdrawAuctionBorrow(uint256 borrow) external view returns (uint256) {
        (, int256 deltaUserCollateral, ) = calculateExecuteWithdrawAuctionBorrow(borrow);
        return uint256(deltaUserCollateral);
    }

    function _executeWithdrawAuction(int256 deltaUserBorrow, int256 deltaUserCollateral, int256 protocolReward) internal {
        borrowToken.transferFrom(msg.sender, address(this), uint256(deltaUserBorrow));
        repay(uint256(deltaUserBorrow + protocolReward));
        withdraw(uint256(deltaUserCollateral));
        collateralToken.transfer(msg.sender, uint256(deltaUserCollateral));
        if (protocolReward != 0) {
          borrowToken.transfer(FEE_COLLECTOR, uint256(-protocolReward));
        }
    }

    function calculateExecuteWithdrawAuctionBorrow(uint256 borrow) internal view returns (int256, int256, int256) {
        require(futureCollateralAssets < 0, NoWithdrawAuction());

        int256 deltaUserBorrow = int256(borrow);
        int256 deltaFutureBorrow = (deltaUserBorrow * int256(Constants.AMOUNT_OF_STEPS) * futureBorrowAssets) /
            (int256(Constants.AMOUNT_OF_STEPS) * futureBorrowAssets + int256(getAuctionStep()) * futureRewardBorrowAssets);

        int256 deltaFutureCollateral = (deltaFutureBorrow * futureCollateralAssets) / futureBorrowAssets;
        int256 deltaUserCollateral = deltaFutureCollateral;

        int256 deltaFutureRewardBorrow = futureRewardBorrowAssets.mulDivDown(deltaFutureBorrow, futureBorrowAssets);
        int256 deltaUserFutureRewardBorrowAssets = deltaUserBorrow - deltaFutureBorrow;
        int256 deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrow - deltaUserFutureRewardBorrowAssets;

        require(
            deltaUserCollateral > 0 && deltaUserBorrow > 0 && deltaProtocolFutureRewardBorrowAssets <= 0,
            BadWithdrawAuctionPreview(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardBorrowAssets)
        );

        return (deltaUserBorrow, deltaUserCollateral, deltaProtocolFutureRewardBorrowAssets);
    }

    function calculateExecuteWithdrawAuctionCollateral(uint256 collateral) internal view returns (int256, int256, int256) {
        require(futureCollateralAssets < 0, NoWithdrawAuction());

        int256 deltaUserCollateral = int256(collateral);
        int256 deltaFutureCollateral = deltaUserCollateral;

        int256 deltaFutureBorrow = deltaFutureCollateral.mulDivDown(futureBorrowAssets, futureCollateralAssets);
        int256 deltaFutureRewardBorrow = futureRewardBorrowAssets.mulDivDown(deltaFutureBorrow, futureBorrowAssets);
        int256 deltaUserFutureRewardBorrowAssets = deltaFutureRewardBorrow.mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

        int256 deltaUserBorrow = deltaFutureBorrow + deltaUserFutureRewardBorrowAssets;
        int256 deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrow - deltaUserFutureRewardBorrowAssets;

        require(
            deltaUserCollateral > 0 && deltaUserBorrow > 0 && deltaProtocolFutureRewardBorrowAssets <= 0,
            BadWithdrawAuctionPreview(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardBorrowAssets)
        );

        return (deltaUserBorrow, deltaUserCollateral, deltaProtocolFutureRewardBorrowAssets);
    }
}
