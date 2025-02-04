// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../StateTransition.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./TotalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../Lending.sol";
import "../math/DepositWithdrawBorrow.sol";
import "../math/NextStep.sol";

abstract contract Withdraw is State, StateTransition, TotalAssets, ERC20, DepositWithdrawBorrow, Lending, NextStep{

    using uMulDiv for uint256;

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {

        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = calculateDepositWithdrawBorrow(int256(assets));

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        _burn(owner, shares);

        // TODO: fix this - return from calculateDepositWithdrawBorrow
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        return shares;
    }

}
