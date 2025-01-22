// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./TotalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/MintRedeamBorrow.sol";
import "./TotalAssets.sol";
import "../Lending.sol";
import "../math/DepositWithdrawBorrow.sol";
import "../math/NextStep.sol";
import "./ConvertToAssets.sol";
import "../StateTransition.sol";

abstract contract Mint is State, StateTransition, MintRedeamBorrow, TotalAssets, ERC20, Lending, DepositWithdrawBorrow, NextStep, ConvertToAssets {

    using uMulDiv for uint256;

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {

        (int256 signedAssets, DeltaFuture memory deltaFuture) = calculateMintRedeamBorrow(-1*int256(convertToAssets(shares)));
        // int256 signedShares = previewMintRedeamBorrow(-1*int256(assets));

        if (signedAssets > 0) {
            return 0;
        }

        assets = uint256(signedAssets);

        uint256 supply = totalSupply();

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
