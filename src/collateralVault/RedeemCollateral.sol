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

    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256 collateralAssets) {
        {
            uint256 max = maxRedeemCollateral(address(owner));
            require(shares <= max, ExceedsMaxRedeemCollateral(owner, shares, max));
            if (owner != receiver) {
                allowance[owner][receiver] -= shares;
            }
        }

        DeltaFuture memory deltaFuture;
        {
            uint256 supplyAfterFee = previewSupplyAfterFee();
            uint256 sharesInAssets = shares.mulDivUp(totalAssets(), supplyAfterFee);
            uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);

            int256 assetsInUnderlying;
            // int256 signedShares = previewMintRedeem(-1*int256(assets));

            ConvertedAssets memory convertedAssets = recoverConvertedAssets();
            Prices memory prices = getPrices();
            (assetsInUnderlying, deltaFuture) = MintRedeem.calculateMintRedeem(
                -int256(sharesInUnderlying),
                false,
                convertedAssets,
                prices,
                targetLTV
            );

            if (assetsInUnderlying > 0) {
                return 0;
            } else {
                collateralAssets = uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.collateral);
            }
            applyMaxGrowthFee(supplyAfterFee);

            if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
                _mint(feeCollector, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
            }

            if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
                _mint(feeCollector, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
            }

            _burn(owner, shares);

            NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

            applyStateTransition(nextState);
        }

        withdraw(collateralAssets);

        collateralToken.transfer(receiver, collateralAssets);

        emit WithdrawCollateral(msg.sender, receiver, owner, collateralAssets, shares);

        return collateralAssets;
    }
}
