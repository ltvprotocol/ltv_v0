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
        uint256 sharesInAssets = shares.mulDivDown(totalAssets(), supplyAfterFee);
        uint256 sharesInUnderlying = sharesInAssets.mulDivDown(getPrices().borrow, Constants.ORACLE_DIVIDER);
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();
        (int256 assetsInUnderlying, DeltaFuture memory deltaFuture) = MintRedeem.calculateMintRedeem(
            int256(sharesInUnderlying),
            true,
            convertedAssets,
            prices,
            targetLTV
        );
        // int256 signedShares = previewMintRedeem(-1*int256(assets));

        if (assetsInUnderlying > 0) {
            return 0;
        }

        assets = uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        
        applyMaxGrowthFee(supplyAfterFee);
        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            _mint(feeCollector, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(feeCollector, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
        }

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdraw

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return assets;
    }
}
