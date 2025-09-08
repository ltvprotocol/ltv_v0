// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC4626Events} from "src/events/IERC4626Events.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemBorrowVaultStateReader.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "src/structs/data/vault/MaxWithdrawRedeemBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {NextState} from "src/structs/state_transition/NextState.sol";
import {NextStateData} from "src/structs/state_transition/NextStateData.sol";
import {NextStepData} from "src/structs/state_transition/NextStepData.sol";
import {MintProtocolRewardsData} from "src/structs/data/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "src/state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "src/state_transition/MintProtocolRewards.sol";
import {Lending} from "src/state_transition/Lending.sol";
import {TransferFromProtocol} from "src/state_transition/TransferFromProtocol.sol";
import {MaxWithdraw} from "src/public/vault/borrow/max/MaxWithdraw.sol";
import {NextStep} from "src/math/libraries/NextStep.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

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

        (uint256 sharesOut, DeltaFuture memory deltaFuture) =
            _previewWithdraw(assets, data.previewWithdrawBorrowVaultData);

        if (sharesOut == 0) {
            return 0;
        }

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, sharesOut);
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

        _burn(owner, sharesOut);

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

        emit Withdraw(msg.sender, receiver, owner, assets, sharesOut);

        return sharesOut;
    }
}
