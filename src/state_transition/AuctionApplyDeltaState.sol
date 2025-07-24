// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./Lending.sol";
import "./TransferFromProtocol.sol";
import "src/structs/state_transition/DeltaAuctionState.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "src/events/IAuctionEvent.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

abstract contract AuctionApplyDeltaState is
    Lending,
    TransferFromProtocol,
    ReentrancyGuardUpgradeable,
    FunctionStopperModifier,
    IAuctionEvent
{
    function applyDeltaState(DeltaAuctionState memory deltaState) internal {
        futureBorrowAssets += deltaState.deltaFutureBorrowAssets;
        futureCollateralAssets += deltaState.deltaFutureCollateralAssets;
        futureRewardBorrowAssets +=
            deltaState.deltaProtocolFutureRewardBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;
        futureRewardCollateralAssets +=
            deltaState.deltaProtocolFutureRewardCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        if (deltaState.deltaUserCollateralAssets < 0) {
            collateralToken.transferFrom(msg.sender, address(this), uint256(-deltaState.deltaUserCollateralAssets));
        }
        int256 supplyAmount =
            -(deltaState.deltaUserCollateralAssets + deltaState.deltaProtocolFutureRewardCollateralAssets);

        if (supplyAmount > 0) {
            supply(uint256(supplyAmount));
        }

        if (deltaState.deltaUserBorrowAssets < 0) {
            borrow(uint256(-deltaState.deltaUserBorrowAssets));
            transferBorrowToken(msg.sender, uint256(-deltaState.deltaUserBorrowAssets));
        }

        if (deltaState.deltaUserBorrowAssets > 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(deltaState.deltaUserBorrowAssets));
        }

        int256 repayAmount = deltaState.deltaUserBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets;
        if (repayAmount > 0) {
            repay(uint256(repayAmount));
        }

        if (deltaState.deltaUserCollateralAssets > 0) {
            withdraw(uint256(deltaState.deltaUserCollateralAssets));
            transferCollateralToken(msg.sender, uint256(deltaState.deltaUserCollateralAssets));
        }

        if (deltaState.deltaProtocolFutureRewardCollateralAssets > 0) {
            transferCollateralToken(feeCollector, uint256(deltaState.deltaProtocolFutureRewardCollateralAssets));
        }

        if (deltaState.deltaProtocolFutureRewardBorrowAssets < 0) {
            transferBorrowToken(feeCollector, uint256(-deltaState.deltaProtocolFutureRewardBorrowAssets));
        }

        emit AuctionExecuted(msg.sender, deltaState.deltaFutureCollateralAssets, deltaState.deltaFutureBorrowAssets);
    }
}
