// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import '../StateTransition.sol';
import './MaxMint.sol';
import '../ERC4626Events.sol';
import '../math/MintRedeem.sol';

abstract contract Mint is MaxMint, StateTransition, Lending, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        uint256 max = maxMint(address(receiver));
        require(shares <= max, ExceedsMaxMint(receiver, shares, max));

        uint256 supplyAfterFee = previewSupplyAfterFee();
        // HODLer <=> Depositor conflict, resolve in favor of HODLer
        // assume user wants to mint more shares to get more assets
        uint256 sharesInUnderlying = shares.mulDivUp(_totalAssets(true), supplyAfterFee).mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);
        
        ConvertedAssets memory convertedAssets = recoverConvertedAssets(true);
        Prices memory prices = getPrices();
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            int256(sharesInUnderlying),
            true,
            convertedAssets,
            prices,
            targetLTV
        );

        if (assetsInUnderlying > 0) {
            return 0;
        }

        // 
        // HODLer <=> Depositor conflict, resolve in favor of HODLer, round up assets to receive more assets
        assets = uint256(-assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.borrow);

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee, true);

        repay(assets);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return assets;
    }
}
