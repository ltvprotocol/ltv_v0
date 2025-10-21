// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DefaultTestData} from "test/utils/BaseTest.t.sol";
import {AuctionTestCommon} from "test/auction/AuctionTestCommon.t.sol";
import {IAuctionErrors} from "src/errors/IAuctionErrors.sol";

contract ExecutionAvailablilityTest is AuctionTestCommon {
    function test_failIfOppositeSignWithdrawAuction(DefaultTestData memory data, address user, uint120 amount)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareWithdrawAuction(amount, data.governor, user);

        int256 deltaFutureBorrowAssetsOppositeSign = ltv.futureBorrowAssets() / 2;
        int256 deltaFutureCollateralAssetsOppositeSign = ltv.futureCollateralAssets() / 2;
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector,
                ltv.futureBorrowAssets(),
                ltv.futureRewardBorrowAssets(),
                deltaFutureBorrowAssetsOppositeSign
            )
        );

        ltv.executeAuctionBorrow(deltaFutureBorrowAssetsOppositeSign);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector,
                ltv.futureCollateralAssets(),
                ltv.futureRewardCollateralAssets(),
                deltaFutureCollateralAssetsOppositeSign
            )
        );
        ltv.executeAuctionCollateral(deltaFutureCollateralAssetsOppositeSign);
    }

    function test_failIfOppositeSignDepositAuction(DefaultTestData memory data, address user, uint120 amount)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.owner);
        vm.assume(user != data.feeCollector);
        vm.assume(user != address(0));
        prepareUser(user);
        prepareDepositAuction(amount, data.owner);

        int256 deltaFutureBorrowAssetsOppositeSign = ltv.futureBorrowAssets() / 2;
        int256 deltaFutureCollateralAssetsOppositeSign = ltv.futureCollateralAssets() / 2;
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector,
                ltv.futureBorrowAssets(),
                ltv.futureRewardBorrowAssets(),
                deltaFutureBorrowAssetsOppositeSign
            )
        );
        ltv.executeAuctionBorrow(deltaFutureBorrowAssetsOppositeSign);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector,
                ltv.futureCollateralAssets(),
                ltv.futureRewardCollateralAssets(),
                deltaFutureCollateralAssetsOppositeSign
            )
        );
        ltv.executeAuctionCollateral(deltaFutureCollateralAssetsOppositeSign);
    }

    function test_failIfExceedsDepositAuctionSize(DefaultTestData memory data, uint120 amount)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareDepositAuction(amount, data.owner);

        int256 deltaFutureCollateralAssetsOverflow = -ltv.futureCollateralAssets() - 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector,
                ltv.futureCollateralAssets(),
                ltv.futureRewardCollateralAssets(),
                deltaFutureCollateralAssetsOverflow
            )
        );
        ltv.executeAuctionCollateral(deltaFutureCollateralAssetsOverflow);

        int256 deltaFutureBorrowAssetsOverflow = -ltv.futureBorrowAssets() - 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector,
                ltv.futureBorrowAssets(),
                ltv.futureRewardBorrowAssets(),
                deltaFutureBorrowAssetsOverflow
            )
        );
        ltv.executeAuctionBorrow(deltaFutureBorrowAssetsOverflow);
    }

    function test_failIfExceedsWithdrawAuctionSize(DefaultTestData memory data, uint120 amount)
        public
        testWithPredefinedDefaultValues(data)
    {
        prepareWithdrawAuction(amount, data.governor, address(this));

        int256 deltaFutureCollateralAssetsOverflow = -ltv.futureCollateralAssets() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral.selector,
                ltv.futureCollateralAssets(),
                ltv.futureRewardCollateralAssets(),
                deltaFutureCollateralAssetsOverflow
            )
        );
        ltv.executeAuctionCollateral(deltaFutureCollateralAssetsOverflow);

        int256 deltaFutureBorrowAssetsOverflow = -ltv.futureBorrowAssets() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow.selector,
                ltv.futureBorrowAssets(),
                ltv.futureRewardBorrowAssets(),
                deltaFutureBorrowAssetsOverflow
            )
        );
        ltv.executeAuctionBorrow(deltaFutureBorrowAssetsOverflow);
    }
}
