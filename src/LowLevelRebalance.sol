// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './MaxGrowthFee.sol';
import './Lending.sol';
import './math/LowLevelRebalanceMath.sol';

abstract contract LowLevelRebalance is MaxGrowthFee, Lending {
    using sMulDiv for int256;

    function previewLowLevelRebalanceShares(int256 deltaShares) external view returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealCollateral, int256 deltaRealBorrow, ) = LowLevelRebalanceMath.calculateLowLevelRebalanceShares(
            deltaShares,
            recoverConvertedAssets(deltaShares > 0),
            getPrices(),
            targetLTV,
            int256(_totalAssets(deltaShares > 0)),
            int256(supplyAfterFee)
        );
        return (deltaRealCollateral, deltaRealBorrow);
    }

    function executeLowLevelRebalanceShares(int256 deltaShares) external isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        applyMaxGrowthFee(supplyAfterFee);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets, int256 deltaProtocolFutureRewardShares) = LowLevelRebalanceMath
            .calculateLowLevelRebalanceShares(
                deltaShares,
                recoverConvertedAssets(deltaShares > 0),
                getPrices(),
                targetLTV,
                int256(_totalAssets(deltaShares > 0)),
                int256(supplyAfterFee)
            );
        executeLowLevelRebalance(deltaRealCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);

        return (deltaRealCollateralAssets, deltaRealBorrowAssets);
    }

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        (int256 deltaRealCollateral, int256 deltaShares, ) = previewLowLevelRebalanceBorrowHint(deltaBorrowAssets, true);

        return (deltaRealCollateral, deltaShares);
    }

    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external returns (int256, int256) {
        return executeLowLevelRebalanceBorrowHint(deltaBorrowAssets, true);
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        (int256 deltaRealBorrow, int256 deltaShares, ) = previewLowLevelRebalanceCollateralHint(deltaCollateralAssets, true);
        return (deltaRealBorrow, deltaShares);
    }

    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external returns (int256, int256) {
        return executeLowLevelRebalanceCollateralHint(deltaCollateralAssets, true);
    }

    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) public isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceBorrowHint(
            deltaBorrowAssets,
            isSharesPositiveHint,
            supplyAfterFee
        );

        applyMaxGrowthFee(supplyAfterFee);

        executeLowLevelRebalance(deltaRealCollateralAssets, deltaBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
        return (deltaRealCollateralAssets, deltaShares);
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelRebalanceBorrowHint(deltaBorrowAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelRebalanceCollateralHint(deltaCollateralAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) public isFunctionAllowed nonReentrant returns (int256, int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = _previewLowLevelRebalanceCollateralHint(
            deltaCollateralAssets,
            isSharesPositiveHint,
            supplyAfterFee
        );

        applyMaxGrowthFee(supplyAfterFee);

        executeLowLevelRebalance(deltaCollateralAssets, deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
        return (deltaRealBorrowAssets, deltaShares);
    }

    function _previewLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint,
        uint256 supply
    ) private view returns (int256, int256, int256) {
        Prices memory prices = getPrices();

        (int256 deltaRealBorrowAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelRebalanceMath.calculateLowLevelRebalanceCollateral(
            deltaCollateralAssets,
            recoverConvertedAssets(isSharesPositiveHint),
            prices,
            targetLTV,
            int256(_totalAssets(isSharesPositiveHint)),
            int256(supply)
        );

        if ((deltaShares > 0) != isSharesPositiveHint) {
            (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares) = LowLevelRebalanceMath.calculateLowLevelRebalanceCollateral(
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

    function _previewLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint,
        uint256 supply
    ) public view returns (int256, int256, int256) {
        Prices memory prices = getPrices();

        (int256 deltaRealCollateralAssets, int256 deltaShares, int256 deltaProtocolFutureRewardShares) = LowLevelRebalanceMath.calculateLowLevelRebalanceBorrow(
            deltaBorrowAssets,
            recoverConvertedAssets(isSharesPositiveHint),
            prices,
            targetLTV,
            int256(_totalAssets(isSharesPositiveHint)),
            int256(supply)
        );

        if ((deltaShares > 0) != isSharesPositiveHint) {
            (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares) = LowLevelRebalanceMath.calculateLowLevelRebalanceBorrow(
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
