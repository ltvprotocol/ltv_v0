// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../StateTransition.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../Lending.sol";
import "../math/DepositWithdrawBorrow.sol";
import "../math/NextStep.sol";

abstract contract PreviewDeposit is State, StateTransition, TotalAssets, ERC20, DepositWithdrawBorrow, Lending, NextStep {

    using uMulDiv for uint256;

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {

        (int256 signedShares, DeltaFuture memory deltaFuture) = calculateDepositWithdrawBorrow(-1*int256(assets));
        
        if (signedShares > 0) {
            return 0;
        } else{
            shares = uint256(signedShares);
        }

        uint256 supply = totalSupply;

        supply = supply == 0 ? shares : shares.mulDivDown(supply, totalAssets());

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdrawBorrow
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        _mint(receiver, shares);

        return shares;
    }

}
