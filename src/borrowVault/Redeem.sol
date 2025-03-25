// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../ERC20.sol';
import '../math/MintRedeem.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import '../StateTransition.sol';
import './MaxRedeem.sol';
import '../ERC4626Events.sol';

abstract contract Redeem is MaxRedeem, StateTransition, Lending, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        {
            uint256 max = maxRedeem(address(owner));
            require(shares <= max, ExceedsMaxRedeem(owner, shares, max));
            if (owner != receiver) {
                allowance[owner][receiver] -= shares;
            }
        }

        uint256 supplyAfterFee = previewSupplyAfterFee();
        // round down to give less assets for provided shares
        Prices memory prices = getPrices();
        uint256 sharesInUnderlying = shares.mulDivDown(totalAssets(), supplyAfterFee).mulDivDown(prices.borrow, Constants.ORACLE_DIVIDER);

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            -int256(sharesInUnderlying),
            true,
            convertedAssets,
            prices,
            targetLTV
        );

        if (assetsInUnderlying < 0) {
            return 0;
        }

        // round down to give less assets
        uint256 assets = uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee);

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }
}
