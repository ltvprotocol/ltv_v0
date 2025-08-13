// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../max/MaxRedeem.sol";
import "../../../../state_transition/VaultStateTransition.sol";
import "../../../../state_transition/ERC20.sol";
import "../../../../state_transition/ApplyMaxGrowthFee.sol";
import "../../../../state_transition/MintProtocolRewards.sol";
import "../../../../state_transition/Lending.sol";
import "src/events/IERC4626Events.sol";
import "../preview/PreviewRedeem.sol";
import "../../../../math/NextStep.sol";
import "../../../../state_transition/TransferFromProtocol.sol";
import "src/errors/IVaultErrors.sol";
import "src/state_reader/vault/MaxWithdrawRedeemBorrowVaultStateReader.sol";

abstract contract Redeem is
    MaxWithdrawRedeemBorrowVaultStateReader,
    MaxRedeem,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    TransferFromProtocol,
    IERC4626Events,
    IVaultErrors
{
    using uMulDiv for uint256;

    function redeem(uint256 shares, address receiver, address owner)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256 assets)
    {
        MaxWithdrawRedeemBorrowVaultState memory state = maxWithdrawRedeemBorrowVaultState(owner);
        MaxWithdrawRedeemBorrowVaultData memory data = maxWithdrawRedeemStateToData(state);
        uint256 max = _maxRedeem(data);
        require(shares <= max, ExceedsMaxRedeem(owner, shares, max));

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }

        (uint256 assetsOut, DeltaFuture memory deltaFuture) =
            _previewRedeem(shares, data.previewWithdrawBorrowVaultData);

        if (assetsOut == 0) {
            return 0;
        }

        applyMaxGrowthFee(
            data.previewWithdrawBorrowVaultData.supplyAfterFee, data.previewWithdrawBorrowVaultData.withdrawTotalAssets
        );

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewWithdrawBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewWithdrawBorrowVaultData.withdrawTotalAssets,
                assetPrice: data.previewWithdrawBorrowVaultData.borrowPrice
            })
        );

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewWithdrawBorrowVaultData.futureBorrow,
                futureCollateral: data.previewWithdrawBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewWithdrawBorrowVaultData.userFutureRewardBorrow
                    + data.previewWithdrawBorrowVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewWithdrawBorrowVaultData.userFutureRewardCollateral
                    + data.previewWithdrawBorrowVaultData.protocolFutureRewardCollateral,
                deltaFutureBorrow: deltaFuture.deltaFutureBorrow,
                deltaFutureCollateral: deltaFuture.deltaFutureCollateral,
                deltaFuturePaymentBorrow: deltaFuture.deltaFuturePaymentBorrow,
                deltaFuturePaymentCollateral: deltaFuture.deltaFuturePaymentCollateral,
                deltaUserFutureRewardBorrow: deltaFuture.deltaUserFutureRewardBorrow,
                deltaUserFutureRewardCollateral: deltaFuture.deltaUserFutureRewardCollateral,
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                blockNumber: uint56(block.number),
                auctionStep: CommonMath.calculateAuctionStep(startAuction, uint56(block.number), auctionDuration)
            })
        );

        applyStateTransition(
            NextStateData({
                nextState: nextState,
                borrowPrice: data.previewWithdrawBorrowVaultData.borrowPrice,
                collateralPrice: state.previewWithdrawVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice
            })
        );

        borrow(assetsOut);

        transferBorrowToken(receiver, assetsOut);

        emit Withdraw(msg.sender, receiver, owner, assetsOut, shares);

        return assetsOut;
    }
}
