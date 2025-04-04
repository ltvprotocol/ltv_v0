// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './MaxGrowthFee.sol';
import './Lending.sol';
import './math/LowLevelMath.sol';

abstract contract LowLevel is MaxGrowthFee, Lending {
    using sMulDiv for int256;

    function previewLowLevelShares(int256 deltaShares) external view returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealCollateral, int256 deltaRealBorrow, ) = LowLevelMath.calculateLowLevelShares(
            deltaShares,
            recoverConvertedAssets(deltaShares > 0),
            getPrices(),
            targetLTV,
            int256(_totalAssets(deltaShares > 0)),
            int256(supplyAfterFee)
        );
        return (deltaRealCollateral, deltaRealBorrow);
    }

    function executeLowLevelShares(int256 deltaShares) external isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        applyMaxGrowthFee(supplyAfterFee);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets, int256 deltaProtocolFutureRewardShares) = LowLevelMath
            .calculateLowLevelShares(
                deltaShares,
                recoverConvertedAssets(deltaShares > 0),
                getPrices(),
                targetLTV,
                int256(_totalAssets(deltaShares > 0)),
                int256(supplyAfterFee)
            );
        executeLowLevel(deltaRealCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaRealBorrowAssets);
    }

    function previewLowLevelBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        (int256 deltaRealCollateral, int256 deltaShares, ) = previewLowLevelBorrowHint(deltaBorrowAssets, true);

        return (deltaRealCollateral, deltaShares);
    }

    function executeLowLevelBorrow(int256 deltaBorrowAssets) external returns (int256, int256) {
        return executeLowLevelBorrowHint(deltaBorrowAssets, true);
    }

    function previewLowLevelCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        (int256 deltaRealBorrow, int256 deltaShares, ) = previewLowLevelCollateralHint(deltaCollateralAssets, true);
        return (deltaRealBorrow, deltaShares);
    }

    function executeLowLevelCollateral(int256 deltaCollateralAssets) external returns (int256, int256) {
        return executeLowLevelCollateralHint(deltaCollateralAssets, true);
    }

    function executeLowLevelBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) public isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelBorrowHint(
            deltaBorrowAssets,
            isSharesPositiveHint,
            supplyAfterFee
        );

        applyMaxGrowthFee(supplyAfterFee);

        executeLowLevel(deltaRealCollateralAssets, deltaBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
        return (deltaRealCollateralAssets, deltaShares);
    }

    function previewLowLevelBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelBorrowHint(deltaBorrowAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function previewLowLevelCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelCollateralHint(deltaCollateralAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function executeLowLevelCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) public isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelCollateralHint(
            deltaCollateralAssets,
            isSharesPositiveHint,
            supplyAfterFee
        );

        applyMaxGrowthFee(supplyAfterFee);

        executeLowLevel(deltaCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
        return (deltaRealBorrowAssets, deltaShares);
    }

    function _previewLowLevelCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        uint256 supply
    ) private view returns (int256, int256, int256) {
        Prices memory prices = getPrices();

        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelCollateral(
            deltaCollateralAssets,
            recoverConvertedAssets(isSharesPositiveHint),
            prices,
            targetLTV,
            int256(_totalAssets(isSharesPositiveHint)),
            int256(supply)
        );

        if ((deltaShares > 0) != isSharesPositiveHint) {
            (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelCollateral(
                deltaCollateralAssets,
                recoverConvertedAssets(!isSharesPositiveHint),
                getPrices(),
                targetLTV,
                int256(_totalAssets(!isSharesPositiveHint)),
                int256(supply)
            );
        }

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    function _previewLowLevelBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        uint256 supply
    ) public view returns (int256, int256, int256) {
        Prices memory prices = getPrices();

        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelBorrow(
            deltaBorrowAssets,
            recoverConvertedAssets(isSharesPositiveHint),
            prices,
            targetLTV,
            int256(_totalAssets(isSharesPositiveHint)),
            int256(supply)
        );

        if ((deltaShares > 0) != isSharesPositiveHint) {
            (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares) = LowLevelMath.calculateLowLevelBorrow(
                deltaBorrowAssets,
                recoverConvertedAssets(!isSharesPositiveHint),
                prices,
                targetLTV,
                int256(_totalAssets(!isSharesPositiveHint)),
                int256(supply)
            );
        }

        return (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares);
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
            _mint(feeCollector, uint256(deltaProtocolFutureRewardShares));
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
