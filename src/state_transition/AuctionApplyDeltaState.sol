// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {DeltaAuctionState} from "../structs/state_transition/DeltaAuctionState.sol";
import {IAuctionEvent} from "../events/IAuctionEvent.sol";
import {FunctionStopperModifier} from "../modifiers/FunctionStopperModifier.sol";
import {Lending} from "Lending.sol";
import {TransferFromProtocol} from "TransferFromProtocol.sol";

/**
 * @title AuctionApplyDeltaState
 * @notice contract contains functionality to apply state changes after auction calculations
 */
abstract contract AuctionApplyDeltaState is
    Lending,
    TransferFromProtocol,
    ReentrancyGuardUpgradeable,
    FunctionStopperModifier,
    IAuctionEvent
{
    using SafeERC20 for IERC20;

    /**
     * @dev function applies state changes after auction calculations
     */
    function applyDeltaState(DeltaAuctionState memory deltaState) internal {
        futureBorrowAssets += deltaState.deltaFutureBorrowAssets;
        futureCollateralAssets += deltaState.deltaFutureCollateralAssets;
        futureRewardBorrowAssets +=
            deltaState.deltaProtocolFutureRewardBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;
        futureRewardCollateralAssets +=
            deltaState.deltaProtocolFutureRewardCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        if (deltaState.deltaUserCollateralAssets < 0) {
            // casting to uint256 is safe because deltaState.deltaUserCollateralAssets is checked to be negative
            // forge-lint: disable-start(unsafe-typecast)
            collateralToken.safeTransferFrom(msg.sender, address(this), uint256(-deltaState.deltaUserCollateralAssets));
        }
        int256 supplyAmount =
            -(deltaState.deltaUserCollateralAssets + deltaState.deltaProtocolFutureRewardCollateralAssets);

        if (supplyAmount > 0) {
            // casting to uint256 is safe because supplyAmount is checked to be positive
            // forge-lint: disable-next-line(unsafe-typecast)
            supply(uint256(supplyAmount));
        }

        if (deltaState.deltaUserBorrowAssets < 0) {
            // casting to uint256 is safe because deltaState.deltaUserBorrowAssets is checked to be negative
            // forge-lint: disable-start(unsafe-typecast)
            borrow(uint256(-deltaState.deltaUserBorrowAssets));
            transferBorrowToken(msg.sender, uint256(-deltaState.deltaUserBorrowAssets));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaState.deltaUserBorrowAssets > 0) {
            // casting to uint256 is safe because deltaState.deltaUserBorrowAssets is checked to be positive
            // forge-lint: disable-start(unsafe-typecast)
            borrowToken.safeTransferFrom(msg.sender, address(this), uint256(deltaState.deltaUserBorrowAssets));
        }

        int256 repayAmount = deltaState.deltaUserBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets;
        if (repayAmount > 0) {
            // casting to uint256 is safe because repayAmount is checked to be positive
            // forge-lint: disable-next-line(unsafe-typecast)
            repay(uint256(repayAmount));
        }

        if (deltaState.deltaUserCollateralAssets > 0) {
            // casting to uint256 is safe because deltaState.deltaUserCollateralAssets is checked to be positive
            // forge-lint: disable-start(unsafe-typecast)
            withdraw(uint256(deltaState.deltaUserCollateralAssets));
            transferCollateralToken(msg.sender, uint256(deltaState.deltaUserCollateralAssets));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaState.deltaProtocolFutureRewardCollateralAssets > 0) {
            // casting to uint256 is safe because deltaState.deltaProtocolFutureRewardCollateralAssets is checked to be positive
            // forge-lint: disable-start(unsafe-typecast)
            collateralToken.safeTransfer(feeCollector, uint256(deltaState.deltaProtocolFutureRewardCollateralAssets));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaState.deltaProtocolFutureRewardBorrowAssets < 0) {
            // casting to uint256 is safe because deltaState.deltaProtocolFutureRewardBorrowAssets is checked to be negative
            // forge-lint: disable-start(unsafe-typecast)
            borrowToken.safeTransfer(feeCollector, uint256(-deltaState.deltaProtocolFutureRewardBorrowAssets));
        }

        emit AuctionExecuted(
            msg.sender,
            deltaState.deltaFutureCollateralAssets + deltaState.deltaProtocolFutureRewardCollateralAssets
                + deltaState.deltaUserFutureRewardCollateralAssets,
            deltaState.deltaFutureBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets
                + deltaState.deltaUserFutureRewardBorrowAssets
        );
    }
}
