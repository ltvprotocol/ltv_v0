// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './MaxGrowthFee.sol';
import './Lending.sol';
import './math/LowLevelMath.sol';

abstract contract LowLevel is MaxGrowthFee, Lending {
    using sMulDiv for int256;

    function executeLowLevelShares(int256 deltaShares) external returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        applyMaxGrowthFee(supplyAfterFee);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets, int256 deltaProtocolFutureRewardShares) = LowLevelMath
            .calculateLowLevelShares(deltaShares, recoverConvertedAssets(), getPrices(), targetLTV, int256(totalAssets()), int256(supplyAfterFee));
        executeLowLevel(deltaRealCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaRealBorrowAssets);
    }

    function executeLowLevelBorrow(int256 deltaBorrowAssets) external returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        applyMaxGrowthFee(supplyAfterFee);
        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelBorrow(
            deltaBorrowAssets,
            recoverConvertedAssets(),
            getPrices(),
            targetLTV,
            int256(totalAssets()),
            int256(supplyAfterFee)
        );
        executeLowLevel(deltaRealCollateralAssets, deltaBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaShares);
    }

    function executeLowLevelCollateral(int256 deltaCollateralAssets) external returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        applyMaxGrowthFee(supplyAfterFee);
        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelCollateral(
            deltaCollateralAssets,
            recoverConvertedAssets(),
            getPrices(),
            targetLTV,
            int256(totalAssets()),
            int256(supplyAfterFee)
        );
        executeLowLevel(deltaCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealBorrowAssets, deltaShares);
    }

    function executeLowLevel(
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
            _mint(FEE_COLLECTOR, uint256(deltaProtocolFutureRewardShares));
        }

        if (deltaShares < 0) {
            _burn(msg.sender, uint256(-deltaShares));
        }

        if (deltaRealCollateralAsset > 0) {
            collateralToken.transferFrom(msg.sender, address(this), uint256(deltaRealCollateralAsset));
            supply(uint256(deltaRealCollateralAsset));
        }

        if (deltaRealBorrowAssets < 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(-deltaRealBorrowAssets));
            repay(uint256(-deltaRealBorrowAssets));
        }

        if (deltaRealCollateralAsset < 0) {
            withdraw(uint256(-deltaRealCollateralAsset));
            collateralToken.transfer(msg.sender, uint256(-deltaRealCollateralAsset));
        }

        if (deltaRealBorrowAssets > 0) {
            borrow(uint256(deltaRealBorrowAssets));
            borrowToken.transfer(msg.sender, uint256(deltaRealBorrowAssets));
        }

        if (deltaShares > 0) {
            _mint(msg.sender, uint256(deltaShares));
        }
    }
}
