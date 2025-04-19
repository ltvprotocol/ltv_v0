// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxWithdraw.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewWithdraw.sol';
import '../../../../math2/NextStep.sol';
import '../../../../state_transition/TransferFromProtocol.sol';

abstract contract Withdraw is
    MaxWithdraw,
    PreviewWithdraw,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    TransferFromProtocol,
    ERC4626Events
{
    using uMulDiv for uint256;

    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);

    function withdraw(uint256 assets, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256) {
        WithdrawRedeemData memory data = withdrawRedeemStateToData(withdrawRedeemState(owner));
        uint256 max = _maxWithdraw(data);
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewWithdraw(assets, data.vaultData);

        if (shares == 0) {
            return 0;
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        applyMaxGrowthFee(data.vaultData.supplyAfterFee, data.vaultData.totalAssets);

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.vaultData.supplyAfterFee,
                totalAssets: data.vaultData.totalAssets,
                borrowPrice: data.vaultData.borrowPrice
            })
        );

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.vaultData.futureBorrow,
                futureCollateral: data.vaultData.futureCollateral,
                futureRewardBorrow: data.vaultData.userFutureRewardBorrow + data.vaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.vaultData.userFutureRewardCollateral + data.vaultData.protocolFutureRewardCollateral,
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

        borrow(assets);

        transferBorrowToken(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }
}
