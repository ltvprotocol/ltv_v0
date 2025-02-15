// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "../ERC20.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import "../StateTransition.sol";
import './MaxMintCollateral.sol';

abstract contract MintCollateral is MaxMintCollateral, ERC20, StateTransition, Lending, NextStep {

    using uMulDiv for uint256;

    error ExceedsMaxMintCollateral(address receiver, uint256 shares, uint256 max);

    function mintCollateral(uint256 shares, address receiver) external returns (uint256 collateralAssets) {
        uint256 max = maxMintCollateral(address(receiver));
        require(shares <= max, ExceedsMaxMintCollateral(receiver, shares, max));

        uint256 sharesInAssets = shares.mulDivDown(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = calculateMintRedeem(int256(sharesInUnderlying), false);
        // int256 signedShares = previewMintRedeem(-1*int256(assets));

        if (assetsInUnderlying < 0) {
            return 0;
        }

        collateralAssets = uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);

        supply(collateralAssets);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        _mint(receiver, shares);

        return collateralAssets;
    }

}
