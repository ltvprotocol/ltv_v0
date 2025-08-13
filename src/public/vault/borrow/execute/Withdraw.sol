// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../max/MaxWithdraw.sol";
import "../../../../state_transition/VaultStateTransition.sol";
import "../../../../state_transition/ERC20.sol";
import "../../../../state_transition/ApplyMaxGrowthFee.sol";
import "../../../../state_transition/MintProtocolRewards.sol";
import "../../../../state_transition/Lending.sol";
import "src/events/IERC4626Events.sol";
import "../preview/PreviewWithdraw.sol";
import "../../../../math/NextStep.sol";
import "../../../../state_transition/TransferFromProtocol.sol";
import "src/errors/IVaultErrors.sol";
import "src/state_reader/vault/MaxWithdrawRedeemBorrowVaultStateReader.sol";

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

    function withdraw(uint256 assets, address receiver, address owner)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxWithdrawRedeemBorrowVaultState memory state = maxWithdrawRedeemBorrowVaultState(owner);
        MaxWithdrawRedeemBorrowVaultData memory data = maxWithdrawRedeemStateToData(state);
        uint256 max = _maxWithdraw(data);
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewWithdraw(assets, data.previewWithdrawBorrowVaultData);

        if (shares == 0) {
            return 0;
        }

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
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

        borrow(assets);

        transferBorrowToken(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }
}
