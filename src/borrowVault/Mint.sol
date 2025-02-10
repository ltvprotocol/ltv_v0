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

abstract contract Mint is State, StateTransition, TotalAssets, ERC20, MintRedeamBorrow, Lending, NextStep {

    using uMulDiv for uint256;

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        uint256 sharesInAssets = shares.mulDivDown(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivDown(getPrices().borrow, Constants.ORACLE_DIVIDER);
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = calculateMintRedeamBorrow(int256(sharesInUnderlying));
        // int256 signedShares = previewMintRedeamBorrow(-1*int256(assets));

        if (assetsInUnderlying > 0) {
            return 0;
        }

        assets = uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdrawBorrow
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        _mint(receiver, shares);

        return assets;
    }

}
