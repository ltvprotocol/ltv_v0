// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./ERC20.sol";
import "./TransferFromProtocol.sol";
import "./Lending.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "src/events/ILowLevelRebalanceEvent.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ExecuteLowLevelRebalance is
    FunctionStopperModifier,
    ERC20,
    TransferFromProtocol,
    Lending,
    ILowLevelRebalanceEvent
{
    using SafeERC20 for IERC20;

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
            _mint(feeCollector, uint256(deltaProtocolFutureRewardShares));
        }

        if (deltaShares < 0) {
            _burn(msg.sender, uint256(-deltaShares));
        }

        if (deltaRealCollateralAsset > 0) {
            collateralToken.safeTransferFrom(msg.sender, address(this), uint256(deltaRealCollateralAsset));
            supply(uint256(deltaRealCollateralAsset));
        }

        if (deltaRealBorrowAssets < 0) {
            borrowToken.safeTransferFrom(msg.sender, address(this), uint256(-deltaRealBorrowAssets));
            repay(uint256(-deltaRealBorrowAssets));
        }

        if (deltaRealCollateralAsset < 0) {
            withdraw(uint256(-deltaRealCollateralAsset));
            transferCollateralToken(msg.sender, uint256(-deltaRealCollateralAsset));
        }

        if (deltaRealBorrowAssets > 0) {
            borrow(uint256(deltaRealBorrowAssets));
            transferBorrowToken(msg.sender, uint256(deltaRealBorrowAssets));
        }

        if (deltaShares > 0) {
            _mint(msg.sender, uint256(deltaShares));
        }

        emit LowLevelRebalanceExecuted(msg.sender, deltaRealCollateralAsset, deltaRealBorrowAssets, deltaShares);
    }
}
