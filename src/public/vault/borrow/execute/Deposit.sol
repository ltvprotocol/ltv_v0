// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxDeposit.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewDeposit.sol';
import '../../../../math2/NextStep.sol';

abstract contract Deposit is MaxDeposit, ApplyMaxGrowthFee, MintProtocolRewards, Lending, VaultStateTransition, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);

    function deposit(uint256 assets, address receiver) external isFunctionAllowed nonReentrant returns (uint256) {
        DepositMintData memory data = depositMintStateToData(depositMintState());
        uint256 max = _maxDeposit(data);
        require(assets <= max, ExceedsMaxDeposit(receiver, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewDeposit(assets, data.vaultData);

        if (shares == 0) {
            return 0;
        }

        borrowToken.transferFrom(msg.sender, address(this), assets);

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

        repay(assets);

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

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
