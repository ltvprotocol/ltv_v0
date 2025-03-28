// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../StateTransition.sol';
import '../Constants.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import './MaxWithdrawCollateral.sol';
import '../math/DepositWithdraw.sol';
import '../ERC4626Events.sol';

abstract contract WithdrawCollateral is MaxWithdrawCollateral, StateTransition, Lending, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxWithdrawCollateral(address owner, uint256 collateralAssets, uint256 max);

    function withdrawCollateral(uint256 collateralAssets, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256 shares) {
        uint256 max = maxWithdrawCollateral(address(owner));
        require(collateralAssets <= max, ExceedsMaxWithdrawCollateral(owner, collateralAssets, max));

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();
        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = DepositWithdraw.calculateDepositWithdraw(
            -int256(collateralAssets),
            false,
            convertedAssets,
            prices,
            targetLTV
        );

        uint256 supplyAfterFee = previewSupplyAfterFee();
        if (sharesInUnderlying > 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
            shares = sharesInAssets.mulDivDown(supplyAfterFee, totalAssets());
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee);

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        withdraw(collateralAssets);

        collateralToken.transfer(receiver, collateralAssets);

        emit WithdrawCollateral(msg.sender, receiver, owner, collateralAssets, shares);

        return shares;
    }
}
