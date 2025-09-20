// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILowLevelRebalanceEvent} from "src/events/ILowLevelRebalanceEvent.sol";
import {FunctionStopperModifier} from "src/modifiers/FunctionStopperModifier.sol";
import {ERC20} from "src/state_transition/ERC20.sol";
import {TransferFromProtocol} from "src/state_transition/TransferFromProtocol.sol";
import {Lending} from "src/state_transition/Lending.sol";

/**
 * @title ExecuteLowLevelRebalance
 * @notice contract contains functionality to execute
 * state changes after low level rebalance calculations
 */
abstract contract ExecuteLowLevelRebalance is
    FunctionStopperModifier,
    ERC20,
    TransferFromProtocol,
    Lending,
    ILowLevelRebalanceEvent
{
    using SafeERC20 for IERC20;

    /**
     * @dev Executes state changes after low level rebalance calculations
     */
    function executeLowLevelRebalance(
        int256 deltaRealCollateralAsset,
        int256 deltaRealBorrowAssets,
        int256 deltaShares,
        int256 deltaProtocolFutureRewardShares
    ) internal {
        futureBorrowAssets = 0;
        futureCollateralAssets = 0;
        futureRewardBorrowAssets = 0;
        futureRewardCollateralAssets = 0;
        startAuction = 0;

        if (deltaProtocolFutureRewardShares > 0) {
            // casting to uint256 is safe because deltaProtocolFutureRewardShares is checked to be positive
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            _mintToFeeCollector(uint256(deltaProtocolFutureRewardShares));
        }

        if (deltaShares < 0) {
            // casting to uint256 is safe because deltaShares is checked to be negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            _burn(msg.sender, uint256(-deltaShares));
        }

        if (deltaRealCollateralAsset > 0) {
            // casting to uint256 is safe because deltaRealCollateralAsset is checked to be positive
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-start(unsafe-typecast)
            collateralToken.safeTransferFrom(msg.sender, address(this), uint256(deltaRealCollateralAsset));
            supply(uint256(deltaRealCollateralAsset));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaRealBorrowAssets < 0) {
            // casting to uint256 is safe because deltaRealBorrowAssets is checked to be negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-start(unsafe-typecast)
            borrowToken.safeTransferFrom(msg.sender, address(this), uint256(-deltaRealBorrowAssets));
            repay(uint256(-deltaRealBorrowAssets));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaRealCollateralAsset < 0) {
            // casting to uint256 is safe because deltaRealCollateralAsset is checked to be negative
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-start(unsafe-typecast)
            withdraw(uint256(-deltaRealCollateralAsset));
            transferCollateralToken(msg.sender, uint256(-deltaRealCollateralAsset));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaRealBorrowAssets > 0) {
            // casting to uint256 is safe because deltaRealBorrowAssets is checked to be positive
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-start(unsafe-typecast)
            borrow(uint256(deltaRealBorrowAssets));
            transferBorrowToken(msg.sender, uint256(deltaRealBorrowAssets));
            // forge-lint: disable-end(unsafe-typecast)
        }

        if (deltaShares > 0) {
            // casting to uint256 is safe because deltaShares is checked to be positive
            // and therefore it is smaller than type(uint256).max
            // forge-lint: disable-next-line(unsafe-typecast)
            _mintToUser(msg.sender, uint256(deltaShares));
        }

        emit LowLevelRebalanceExecuted(msg.sender, deltaRealCollateralAsset, deltaRealBorrowAssets, deltaShares);
    }
}
