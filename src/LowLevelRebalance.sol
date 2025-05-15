// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './MaxGrowthFee.sol';
import './Lending.sol';
import './math/LowLevelRebalanceMath.sol';

abstract contract LowLevelRebalance is MaxGrowthFee, Lending {
    using sMulDiv for int256;
    using uMulDiv for uint256;

    error ExceedsLowLevelRebalanceMaxDeltaCollareral(int256 deltaCollateral, int256 max);
    error ExceedsLowLevelRebalanceMaxDeltaBorrow(int256 deltaBorrow, int256 max);
    error ExceedsLowLevelRebalanceMaxDeltaShares(int256 deltaShares, int256 max);

    function maxLowLevelRebalanceBorrow() public view returns (int256) {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInBorrow = maxTotalAssetsInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        // rounding down assuming smaller border
        uint256 maxBorrow = maxTotalAssetsInBorrow.mulDivDown(Constants.LTV_DIVIDER * targetLTV, (Constants.LTV_DIVIDER - targetLTV) * Constants.LTV_DIVIDER);
        // round up to assume smaller border
        uint256 currentBorrow = getRealBorrowAssets(false);
        return int256(maxBorrow) - int256(currentBorrow);
    }

    function maxLowLevelRebalanceCollateral() public view returns(int256) {
        // rounding down assuming smaller border
        uint256 maxTotalAssetsInCollateral = maxTotalAssetsInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
        // rounding down assuming smaller border
        uint256 maxCollateral = maxTotalAssetsInCollateral.mulDivDown(Constants.LTV_DIVIDER, Constants.LTV_DIVIDER - targetLTV);
        // rounding up assuming smaller border
        uint256 currentCollateral = getRealCollateralAssets(true);
        return int256(maxCollateral) - int256(currentCollateral);
    }

    function maxLowLevelRebalanceShares() public view returns(int256) {
        uint256 supplyAfterFee = previewSupplyAfterFee();
        uint256 borrowPrice = getPriceBorrowOracle();
        // rounding up assuming smaller border
        uint256 realCollateralUnderlying = getRealCollateralAssets(true).mulDivUp(getPriceCollateralOracle(), Constants.ORACLE_DIVIDER);
        // rounding down assuming smaller border
        uint256 realBorrowUnderlying = getRealBorrowAssets(true).mulDivDown(borrowPrice, Constants.ORACLE_DIVIDER);

        int256 maxDeltaSharesInUnderlying = int256(maxTotalAssetsInUnderlying + realBorrowUnderlying) - int256(realCollateralUnderlying);
        uint256 totalAssets = maxDeltaSharesInUnderlying > 0 ? _totalAssets(true) : _totalAssets(false);

        // rounding down assuming smaller border
        return maxDeltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(borrowPrice)).mulDivDown(int256(supplyAfterFee), int256(totalAssets));
    }

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

    function previewLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external view returns (int256, int256) {
        (int256 deltaRealCollateral, int256 deltaShares, ) = previewLowLevelRebalanceBorrowHint(deltaBorrowAssets, true);

        return (deltaRealCollateral, deltaShares);
    }

    function previewLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external view returns (int256, int256) {
        (int256 deltaRealBorrow, int256 deltaShares, ) = previewLowLevelRebalanceCollateralHint(deltaCollateralAssets, true);
        return (deltaRealBorrow, deltaShares);
    }

    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelRebalanceBorrowHint(deltaBorrowAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) public view returns (int256, int256, int256) {
        return _previewLowLevelRebalanceCollateralHint(deltaCollateralAssets, isSharesPositiveHint, previewSupplyAfterFee());
    }

    function executeLowLevelRebalanceShares(int256 deltaShares) external isFunctionAllowed nonReentrant returns (int256, int256) {
        int256 max = maxLowLevelRebalanceShares();
        require(deltaShares <= max, ExceedsLowLevelRebalanceMaxDeltaShares(deltaShares, max));
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

    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrowAssets, true);
    }

    function executeLowLevelRebalanceBorrowHint(
        int256 deltaBorrowAssets,
        bool isSharesPositiveHint
    ) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceBorrowHint(deltaBorrowAssets, isSharesPositiveHint);
    }

    function executeLowLevelRebalanceCollateralHint(
        int256 deltaCollateralAssets,
        bool isSharesPositiveHint
    ) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateralAssets, isSharesPositiveHint);
    }

    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external isFunctionAllowed nonReentrant returns (int256, int256) {
        return _executeLowLevelRebalanceCollateralHint(deltaCollateralAssets, true);
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

    function _executeLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) private returns (int256, int256) {
        int256 max = maxLowLevelRebalanceCollateral();
        require(deltaCollateralAssets <= max, ExceedsLowLevelRebalanceMaxDeltaShares(deltaCollateralAssets, max));
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

    function _executeLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) private returns (int256, int256) {
        int256 max = maxLowLevelRebalanceBorrow();
        require(deltaBorrowAssets <= max, ExceedsLowLevelRebalanceMaxDeltaBorrow(deltaBorrowAssets, max));
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
            transferCollateralToken(msg.sender, uint256(-deltaRealCollateralAsset));
        }

        if (deltaRealBorrowAssets > 0) {
            borrow(uint256(deltaRealBorrowAssets));
            transferBorrowToken(msg.sender, uint256(deltaRealBorrowAssets));
        }

        if (deltaShares > 0) {
            _mint(msg.sender, uint256(deltaShares));
        }
    }
}
