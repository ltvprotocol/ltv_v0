// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "../ERC20.sol";
import "../math/MintRedeem.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import "../StateTransition.sol";
import './MaxRedeemCollateral.sol';

abstract contract RedeemCollateral is MaxRedeemCollateral, ERC20, StateTransition, Lending, NextStep{

    using uMulDiv for uint256;

    error ExceedsMaxRedeemCollateral(address owner, uint256 shares, uint256 max);

    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256 collateralAssets) {
        uint256 max = maxRedeemCollateral(address(owner));
        require(shares <= max, ExceedsMaxRedeemCollateral(owner, shares, max));
        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);

        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = calculateMintRedeem(-int256(sharesInUnderlying), false);
        // int256 signedShares = previewMintRedeem(-1*int256(assets));

        if (assetsInUnderlying > 0) {
            return 0;
        } else {
            collateralAssets = uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
        }

        _burn(owner, shares);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        withdraw(collateralAssets);

        collateralToken.transfer(receiver, collateralAssets);

        return collateralAssets;
    }

}
