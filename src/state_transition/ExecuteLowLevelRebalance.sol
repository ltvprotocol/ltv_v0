// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./ERC20.sol";
import "./TransferFromProtocol.sol";
import "./Lending.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "src/events/ILowLevelRebalanceEvent.sol";
import "forge-std/console.sol";

abstract contract ExecuteLowLevelRebalance is
    FunctionStopperModifier,
    ERC20,
    TransferFromProtocol,
    Lending,
    ILowLevelRebalanceEvent
{
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

        console.log("deltaRealCollateralAsset", deltaRealCollateralAsset);
        console.log("deltaRealBorrowAssets", deltaRealBorrowAssets);
        console.log("deltaShares", deltaShares);
        console.log("deltaProtocolFutureRewardShares", deltaProtocolFutureRewardShares);


        console.log("one");
        if (deltaProtocolFutureRewardShares > 0) {
            _mint(feeCollector, uint256(deltaProtocolFutureRewardShares));
        }

        console.log("two");
        if (deltaShares < 0) {
            _burn(msg.sender, uint256(-deltaShares));
        }

        console.log("three");
        if (deltaRealCollateralAsset > 0) {
            collateralToken.transferFrom(msg.sender, address(this), uint256(deltaRealCollateralAsset));
            supply(uint256(deltaRealCollateralAsset));
        }

        console.log("four");
        if (deltaRealBorrowAssets < 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(-deltaRealBorrowAssets));
            repay(uint256(-deltaRealBorrowAssets));
        }

        console.log("five");
        if (deltaRealCollateralAsset < 0) {
            withdraw(uint256(-deltaRealCollateralAsset));
            transferCollateralToken(msg.sender, uint256(-deltaRealCollateralAsset));
        }

        console.log("six");
        if (deltaRealBorrowAssets > 0) {
            borrow(uint256(deltaRealBorrowAssets));
            transferBorrowToken(msg.sender, uint256(deltaRealBorrowAssets));
        }

        console.log("seven");
        if (deltaShares > 0) {
            _mint(msg.sender, uint256(deltaShares));
        }

        console.log("eight");
        emit LowLevelRebalanceExecuted(
            msg.sender, deltaRealCollateralAsset, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares
        );
    }
}
