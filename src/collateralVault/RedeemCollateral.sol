// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../ERC20.sol';
import '../math/MintRedeem.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import '../StateTransition.sol';
import './MaxRedeemCollateral.sol';
import '../ERC4626Events.sol';

abstract contract RedeemCollateral is MaxRedeemCollateral, StateTransition, Lending, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxRedeemCollateral(address owner, uint256 shares, uint256 max);

    function redeemCollateral(uint256 shares, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256 collateralAssets) {
        {
            uint256 max = maxRedeemCollateral(address(owner));
            require(shares <= max, ExceedsMaxRedeemCollateral(owner, shares, max));
            if (owner != receiver) {
                allowance[owner][receiver] -= shares;
            }
        }

        Prices memory prices = getPrices();
        uint256 supplyAfterFee = previewSupplyAfterFee();

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral
        uint256 sharesInUnderlying = shares.mulDivDown(_totalAssets(false), supplyAfterFee).mulDivDown(prices.borrow, Constants.ORACLE_DIVIDER);

        ConvertedAssets memory convertedAssets = recoverConvertedAssets(false);
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            -int256(sharesInUnderlying),
            false,
            convertedAssets,
            prices,
            targetLTV
        );

        if (assetsInUnderlying > 0) {
            return 0;
        }
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less collateral
        collateralAssets = uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.collateral);

        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee, false);

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        withdraw(collateralAssets);

        collateralToken.transfer(receiver, collateralAssets);

        emit WithdrawCollateral(msg.sender, receiver, owner, collateralAssets, shares);

        return collateralAssets;
    }
}
