// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../max/MaxDeposit.sol";
import "../../../../state_transition/VaultStateTransition.sol";
import "../../../../state_transition/ERC20.sol";
import "../../../../state_transition/ApplyMaxGrowthFee.sol";
import "../../../../state_transition/MintProtocolRewards.sol";
import "../../../../state_transition/Lending.sol";
import "src/events/IERC4626Events.sol";
import "../preview/PreviewDeposit.sol";
import "../../../../math/NextStep.sol";
import "src/errors/IVaultErrors.sol";
import "src/state_reader/vault/MaxDepositMintBorrowVaultStateReader.sol";

abstract contract Deposit is
    MaxDepositMintBorrowVaultStateReader,
    MaxDeposit,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    IERC4626Events,
    IVaultErrors
{
    using uMulDiv for uint256;

    function deposit(uint256 assets, address receiver) external isFunctionAllowed nonReentrant returns (uint256) {
        MaxDepositMintBorrowVaultState memory state = maxDepositMintBorrowVaultState();
        MaxDepositMintBorrowVaultData memory data = maxDepositMintStateToData(state);
        uint256 max = _maxDeposit(data);
        require(assets <= max, ExceedsMaxDeposit(receiver, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewDeposit(assets, data.previewDepositBorrowVaultData);

        if (shares == 0) {
            return 0;
        }

        borrowToken.transferFrom(msg.sender, address(this), assets);

        applyMaxGrowthFee(
            data.previewDepositBorrowVaultData.supplyAfterFee, data.previewDepositBorrowVaultData.withdrawTotalAssets
        );

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewDepositBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewDepositBorrowVaultData.depositTotalAssets,
                assetPrice: data.previewDepositBorrowVaultData.borrowPrice
            })
        );

        repay(assets);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewDepositBorrowVaultData.futureBorrow,
                futureCollateral: data.previewDepositBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewDepositBorrowVaultData.userFutureRewardBorrow
                    + data.previewDepositBorrowVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewDepositBorrowVaultData.userFutureRewardCollateral
                    + data.previewDepositBorrowVaultData.protocolFutureRewardCollateral,
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
                borrowPrice: data.previewDepositBorrowVaultData.borrowPrice,
                collateralPrice: state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice
            })
        );

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
