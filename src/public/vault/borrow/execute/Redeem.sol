// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxRedeem.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewRedeem.sol';
import '../../../../math2/NextStep.sol';
import '../../../../state_transition/TransferFromProtocol.sol';

abstract contract Redeem is
    MaxRedeem,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    PreviewRedeem,
    VaultStateTransition,
    TransferFromProtocol,
    ERC4626Events
{
    using uMulDiv for uint256;

    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);

    function redeem(uint256 shares, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256 assets) {
        WithdrawRedeemData memory data = withdrawRedeemStateToData(withdrawRedeemState(owner));
        uint256 max = _maxRedeem(data);
        require(shares <= max, ExceedsMaxRedeem(owner, shares, max));

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        (uint256 assetsOut, DeltaFuture memory deltaFuture) = _previewRedeem(shares, data.vaultData);

        if (assetsOut == 0) {
            return 0;
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

        borrow(assetsOut);

        transferBorrowToken(receiver, assetsOut);

        emit Withdraw(msg.sender, receiver, owner, assetsOut, shares);

        return assetsOut;
    }
}
