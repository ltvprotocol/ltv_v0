// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxDeposit.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import 'src/events/IERC4626Events.sol';
import '../preview/PreviewDeposit.sol';
import '../../../../math2/NextStep.sol';
import 'src/errors/IVaultErrors.sol';

abstract contract Deposit is MaxDeposit, ApplyMaxGrowthFee, MintProtocolRewards, Lending, VaultStateTransition, IERC4626Events, IVaultErrors {
    using uMulDiv for uint256;

    function deposit(uint256 assets, address receiver) external isFunctionAllowed nonReentrant returns (uint256) {
        MaxDepositMintBorrowVaultState memory state = maxDepositMintBorrowVaultState();
        MaxDepositMintBorrowVaultData memory data = maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(state);
        uint256 max = _maxDeposit(data);
        require(assets <= max, ExceedsMaxDeposit(receiver, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewDeposit(assets, data.previewBorrowVaultData);

        if (shares == 0) {
            return 0;
        }

        borrowToken.transferFrom(msg.sender, address(this), assets);

        uint256 withdrawTotalAssets = _totalAssets(
            false,
            TotalAssetsData({
                collateral: data.previewBorrowVaultData.collateral,
                borrow: data.previewBorrowVaultData.borrow,
                borrowPrice: data.previewBorrowVaultData.borrowPrice
            })
        );

        applyMaxGrowthFee(data.previewBorrowVaultData.supplyAfterFee, withdrawTotalAssets);

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewBorrowVaultData.totalAssets,
                assetPrice: data.previewBorrowVaultData.borrowPrice
            })
        );

        repay(assets);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewBorrowVaultData.futureBorrow,
                futureCollateral: data.previewBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewBorrowVaultData.userFutureRewardBorrow + data.previewBorrowVaultData.protocolFutureRewardBorrow,
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

        applyStateTransition(
            NextStateData({
                nextState: nextState,
                borrowPrice: data.previewBorrowVaultData.borrowPrice,
                collateralPrice: state.previewVaultState.maxGrowthFeeState.totalAssetsState.collateralPrice
            })
        );

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
