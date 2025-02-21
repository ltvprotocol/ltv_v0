// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "../ERC20.sol";
import "../math/MintRedeem.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import "../StateTransition.sol";
import './MaxRedeem.sol';
import '../ERC4626Events.sol';

abstract contract Redeem is MaxRedeem, ERC20, StateTransition, Lending, NextStep, ERC4626Events{

    using uMulDiv for uint256;

    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        uint256 max = maxRedeem(address(owner));
        require(shares <= max, ExceedsMaxRedeem(owner, shares, max));
        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);

        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = calculateMintRedeem(-int256(sharesInUnderlying), true);
        // int256 signedShares = previewMintRedeem(-1*int256(assets));

        if (assetsInUnderlying < 0) {
            return 0;
        } else {
            assets = uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
        }

        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
        }
        
        _burn(owner, shares);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;

    }

}
