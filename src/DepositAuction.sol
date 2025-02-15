// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './State.sol';
import './Lending.sol';
import 'forge-std/console.sol';

abstract contract DepositAuction is State, Lending {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    error NoDepositAuction();
    error BadDepositAuctionPreview(int256 deltaUserCollateral, int256 deltaUserBorrow, int256 deltaProtocolFutureRewardCollateralAssets);

    function executeDepositAuctionBorrow(uint256 borrow) external returns (uint256) {
        (int256 deltaUserCollateral, int256 deltaUserBorrow, int256 deltaProtocolFutureRewardCollateralAssets) = calculateExecuteDepositAuctionBorrow(
            borrow
        );

        _executeDepositAuction(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets);
        return uint256(-deltaUserCollateral);
    }

    function executeDepositAuctionCollateral(uint256 collateral) external returns (uint256) {
        (
            int256 deltaUserCollateral,
            int256 deltaUserBorrow,
            int256 deltaProtocolFutureRewardCollateralAssets
        ) = calculateExecuteDepositAuctionCollateral(collateral);

        _executeDepositAuction(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets);
        return uint256(-deltaUserBorrow);
    }

    function previewExecuteDepositAuctionBorrow(uint256 borrow) external view returns (uint256) {
        (int256 deltaUserCollateral, , ) = calculateExecuteDepositAuctionBorrow(borrow);
        return uint256(-deltaUserCollateral);
    }

    function previewExecuteDepositAuctionCollateral(uint256 collateral) external view returns (uint256) {
        (, int256 deltaUserBorrow, ) = calculateExecuteDepositAuctionCollateral(collateral);
        return uint256(-deltaUserBorrow);
    }

    function _executeDepositAuction(int256 deltaUserCollateral, int256 deltaUserBorrow, int256 protocolReward) internal {
        collateralToken.transferFrom(msg.sender, address(this), uint256(-deltaUserCollateral));
        supply(uint256(-deltaUserCollateral - protocolReward));
        borrow(uint256(-deltaUserBorrow));
        borrowToken.transfer(msg.sender, uint256(-deltaUserBorrow));
        if (protocolReward != 0) {
            collateralToken.transfer(FEE_COLLECTOR, uint256(protocolReward));
        }
    }

    function calculateExecuteDepositAuctionCollateral(uint256 collateral) internal view returns (int256, int256, int256) {
        require(futureBorrowAssets > 0, NoDepositAuction());

        int256 deltaUserCollateral = -int256(collateral);
        int256 deltaFutureCollateral = (deltaUserCollateral * int256(Constants.AMOUNT_OF_STEPS) * futureCollateralAssets) /
            (int256(Constants.AMOUNT_OF_STEPS) * futureCollateralAssets + int256(getAuctionStep()) * futureRewardCollateralAssets);

        int256 deltaFutureBorrow = (deltaFutureCollateral * futureBorrowAssets) / futureCollateralAssets;
        int256 deltaUserBorrow = deltaFutureBorrow;

        int256 deltaFutureRewardCollateral = futureRewardCollateralAssets.mulDivDown(deltaFutureCollateral, futureCollateralAssets);
        int256 deltaUserFutureRewardCollateralAssets = deltaUserCollateral - deltaFutureCollateral;
        int256 deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateral - deltaUserFutureRewardCollateralAssets;

        require(
            deltaUserCollateral < 0 && deltaUserBorrow < 0 && deltaProtocolFutureRewardCollateralAssets >= 0,
            BadDepositAuctionPreview(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets)
        );

        return (deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets);
    }

    function calculateExecuteDepositAuctionBorrow(uint256 borrow) internal view returns (int256, int256, int256) {
        require(futureBorrowAssets > 0, NoDepositAuction());

        int256 deltaUserBorrow = -int256(borrow);
        int256 deltaFutureBorrow = deltaUserBorrow;

        int256 deltaFutureCollateral = deltaFutureBorrow.mulDivDown(futureCollateralAssets, futureBorrowAssets);
        int256 deltaFutureRewardCollateral = futureRewardCollateralAssets.mulDivDown(deltaFutureCollateral, futureCollateralAssets);
        int256 deltaUserFutureRewardCollateralAssets = deltaFutureRewardCollateral.mulDivDown(
            int256(getAuctionStep()),
            int256(Constants.AMOUNT_OF_STEPS)
        );

        int256 deltaUserCollateral = deltaFutureCollateral + deltaUserFutureRewardCollateralAssets;
        int256 deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateral - deltaUserFutureRewardCollateralAssets;

        require(
            deltaUserCollateral < 0 && deltaUserBorrow < 0 && deltaProtocolFutureRewardCollateralAssets >= 0,
            BadDepositAuctionPreview(deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets)
        );

        return (deltaUserCollateral, deltaUserBorrow, deltaProtocolFutureRewardCollateralAssets);
    }
}
