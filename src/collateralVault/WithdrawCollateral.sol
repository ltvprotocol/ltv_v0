// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../StateTransition.sol";
import "../Constants.sol";
import "../ERC20.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import './MaxWithdrawCollateral.sol';
import '../math/DepositWithdraw.sol';

abstract contract WithdrawCollateral is MaxWithdrawCollateral, DepositWithdraw, ERC20, StateTransition, Lending, NextStep{

    using uMulDiv for uint256;
    
    error ExceedsMaxWithdrawCollateral(address owner, uint256 collateralAssets, uint256 max);

    function withdrawCollateral(uint256 collateralAssets, address receiver, address owner) external returns (uint256 shares) {
        uint256 max = maxWithdrawCollateral(address(owner));
        require(collateralAssets <= max, ExceedsMaxWithdrawCollateral(owner, collateralAssets, max));

        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = calculateDepositWithdraw(-int256(collateralAssets), false);

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
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

        return shares;
    }

}
