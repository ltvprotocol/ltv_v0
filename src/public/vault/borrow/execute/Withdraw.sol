// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxWithdraw.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import 'src/events/IERC4626Events.sol';
import '../preview/PreviewWithdraw.sol';
import '../../../../math/NextStep.sol';
import '../../../../state_transition/TransferFromProtocol.sol';
import 'src/errors/IVaultErrors.sol';
import 'src/state_reader/MaxWithdrawRedeemBorrowVaultStateReader.sol';
abstract contract Withdraw is
    MaxWithdrawRedeemBorrowVaultStateReader,
    MaxWithdraw,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    TransferFromProtocol,
    IERC4626Events,
    IVaultErrors
{
    using uMulDiv for uint256;

    function withdraw(uint256 assets, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256) {
        MaxWithdrawRedeemBorrowVaultState memory state = maxWithdrawRedeemBorrowVaultState(owner);
        MaxWithdrawRedeemBorrowVaultData memory data = maxWithdrawRedeemBorrowVaultStateToMaxWithdrawRedeemBorrowVaultData(state);
        uint256 max = _maxWithdraw(data);
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewWithdraw(assets, data.previewBorrowVaultData);

        if (shares == 0) {
            return 0;
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        applyMaxGrowthFee(data.previewBorrowVaultData.supplyAfterFee, totalAssets(true, state.previewVaultState.maxGrowthFeeState.totalAssetsState));

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewBorrowVaultData.totalAssets,
                assetPrice: data.previewBorrowVaultData.borrowPrice
            })
        );

        _burn(owner, shares);

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

        borrow(assets);

        transferBorrowToken(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }
}
