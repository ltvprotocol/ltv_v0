// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxMint.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewMint.sol';
import '../../../../math2/NextStep.sol';

abstract contract Mint is MaxMint, ApplyMaxGrowthFee, MintProtocolRewards, Lending, VaultStateTransition, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);

    function mint(uint256 shares, address receiver) external isFunctionAllowed nonReentrant returns (uint256 assets) {
        MaxDepositMintBorrowVaultData memory data = maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(maxDepositMintBorrowVaultState());
        uint256 max = _maxMint(data);
        require(shares <= max, ExceedsMaxMint(receiver, shares, max));

        (uint256 assetsOut, DeltaFuture memory deltaFuture) = _previewMint(shares, data.previewBorrowVaultData);

        if (assetsOut == 0) {
            return 0;
        }

        borrowToken.transferFrom(msg.sender, address(this), assetsOut);

        applyMaxGrowthFee(data.previewBorrowVaultData.supplyAfterFee, data.previewBorrowVaultData.totalAssets);

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewBorrowVaultData.supplyAfterFee,
                totalAssets: data.previewBorrowVaultData.totalAssets,
                borrowPrice: data.previewBorrowVaultData.borrowPrice
            })
        );

        repay(assetsOut);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewBorrowVaultData.futureBorrow,
                futureCollateral: data.previewBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewBorrowVaultData.userFutureRewardBorrow +
                    data.previewBorrowVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewBorrowVaultData.userFutureRewardCollateral +
                    data.previewBorrowVaultData.protocolFutureRewardCollateral,
                deltaFutureBorrow: deltaFuture.deltaFutureBorrow,
                deltaFutureCollateral: deltaFuture.deltaFutureCollateral,
                deltaFuturePaymentBorrow: deltaFuture.deltaFuturePaymentBorrow,
                deltaFuturePaymentCollateral: deltaFuture.deltaFuturePaymentCollateral,
                deltaUserFutureRewardBorrow: deltaFuture.deltaUserFutureRewardBorrow,
                deltaUserFutureRewardCollateral: deltaFuture.deltaUserFutureRewardCollateral,
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                blockNumber: block.number,
                auctionStep: CommonMath.calculateAuctionStep(startAuction, block.number)
            })
        );

        applyStateTransition(nextState);

        emit Deposit(msg.sender, receiver, assetsOut, shares);

        _mint(receiver, shares);

        return assetsOut;
    }
} 