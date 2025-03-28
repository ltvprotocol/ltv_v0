// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import '../StateTransition.sol';
import './MaxMintCollateral.sol';
import '../ERC4626Events.sol';
import '../math/MintRedeem.sol';

abstract contract MintCollateral is MaxMintCollateral, StateTransition, Lending, ERC4626Events {

    using uMulDiv for uint256;

    error ExceedsMaxMintCollateral(address receiver, uint256 shares, uint256 max);

    function mintCollateral(uint256 shares, address receiver) external returns (uint256 collateralAssets) {
        uint256 max = maxMintCollateral(address(receiver));
        require(shares <= max, ExceedsMaxMintCollateral(receiver, shares, max));

        uint256 supplyAfterFee = previewSupplyAfterFee();
        Prices memory prices = getPrices();

        // round up to receive more assets
        uint256 sharesInUnderlying = shares.mulDivUp(totalAssets(), supplyAfterFee).mulDivUp(prices.borrow, Constants.ORACLE_DIVIDER);

        ConvertedAssets memory convertedAssets = recoverConvertedAssets(true);
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            int256(sharesInUnderlying),
            false,
            convertedAssets,
            prices,
            targetLTV
        );

        if (assetsInUnderlying < 0) {
            return 0;
        }

        // round up to get more collateral
        collateralAssets = uint256(assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.collateral);

        // TODO: safeTransfer
        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);

        applyMaxGrowthFee(supplyAfterFee);
        
        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee);

        supply(collateralAssets);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit DepositCollateral(msg.sender, receiver, collateralAssets, shares);

        _mint(receiver, shares);

        return collateralAssets;
    }
}
