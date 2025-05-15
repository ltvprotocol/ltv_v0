// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './Lending.sol';
import './TransferFromProtocol.sol';
import 'src/structs/state_transition/DeltaAuctionState.sol';
import 'src/modifiers/FunctionStopperModifier.sol';
import 'src/events/IAuctionEvent.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

contract AuctionApplyDeltaState is Lending, TransferFromProtocol, ReentrancyGuardUpgradeable, FunctionStopperModifier, IAuctionEvent {

    function applyDeltaState(DeltaAuctionState memory deltaState) internal {
        futureBorrowAssets += deltaState.deltaFutureBorrowAssets;
        futureCollateralAssets += deltaState.deltaFutureCollateralAssets;
        futureRewardBorrowAssets += deltaState.deltaProtocolFutureRewardBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;
        futureRewardCollateralAssets += deltaState.deltaProtocolFutureRewardCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        if (deltaState.deltaUserBorrowAssets < 0) {
            collateralToken.transferFrom(msg.sender, address(this), uint256(-deltaState.deltaUserCollateralAssets));
            supply(uint256(-(deltaState.deltaUserCollateralAssets + deltaState.deltaProtocolFutureRewardCollateralAssets)));
            borrow(uint256(-deltaState.deltaUserBorrowAssets));
            transferBorrowToken(msg.sender, uint256(-deltaState.deltaUserBorrowAssets));
            if (deltaState.deltaProtocolFutureRewardCollateralAssets != 0) {
                transferCollateralToken(feeCollector, uint256(deltaState.deltaProtocolFutureRewardCollateralAssets));
            }
        } else if (deltaState.deltaUserBorrowAssets > 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(deltaState.deltaUserBorrowAssets));
            repay(uint256(deltaState.deltaUserBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets));
            withdraw(uint256(deltaState.deltaUserCollateralAssets));
            transferCollateralToken(msg.sender, uint256(deltaState.deltaUserCollateralAssets));
            if (deltaState.deltaProtocolFutureRewardBorrowAssets != 0) {
                transferBorrowToken(feeCollector, uint256(-deltaState.deltaProtocolFutureRewardBorrowAssets));
            }
        }

        emit AuctionExecuted(msg.sender, deltaState.deltaFutureCollateralAssets, deltaState.deltaFutureBorrowAssets);
    }
}
