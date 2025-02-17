// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "../ERC20.sol";
import "../math/MintRedeem.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import "../StateTransition.sol";
import './MaxRedeemCollateral.sol';
import '../ERC4626Events.sol';

abstract contract RedeemCollateral is MaxRedeemCollateral, ERC20, StateTransition, Lending, NextStep, ERC4626Events {

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

        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            uint256 amountInAssets = uint256(-deltaFuture.deltaProtocolFutureRewardBorrow).mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
            uint256 amountInShares = amountInAssets.mulDivDown(totalSupply(), totalAssets());
            _mint(FEE_COLLECTOR, amountInShares);
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            uint256 amountInAssets = uint256(deltaFuture.deltaProtocolFutureRewardCollateral).mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
            uint256 amountInShares = amountInAssets.mulDivDown(totalSupply(), totalAssets());
            _mint(FEE_COLLECTOR, amountInShares);
        }

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        withdraw(collateralAssets);

        collateralToken.transfer(receiver, collateralAssets);

        emit WithdrawCollateral(msg.sender, receiver, owner, collateralAssets, shares);

        return collateralAssets;
    }

}
