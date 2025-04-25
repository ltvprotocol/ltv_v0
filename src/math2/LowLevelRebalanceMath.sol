// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../Structs2.sol';
import '../Constants.sol';
import '../utils/MulDiv.sol';

library LowLevelRebalanceMath {
    using sMulDiv for int256;

    struct DeltaRealCollateralFromDeltaSharesData {
        int256 deltaShares;
        int256 futureCollateral;
        int256 userFutureRewardCollateral;
        int256 realCollateral;
        int256 realBorrow;
        int256 futureBorrow;
        int256 userFutureRewardBorrow;
        uint128 targetLTV;
    }

    // HODLer <=> depositor/withdrawer conflict, round up to leave more collateral in protocol
    function calculateDeltaRealCollateralFromDeltaShares(DeltaRealCollateralFromDeltaSharesData memory data) private pure returns (int256) {
        return
            (data.deltaShares +
                data.futureCollateral +
                data.userFutureRewardCollateral +
                // round up to leave more collateral in protocol
                data.realCollateral.mulDivUp(int128(data.targetLTV), int256(Constants.LTV_DIVIDER)) -
                data.realBorrow -
                data.futureBorrow -
                data.userFutureRewardBorrow).mulDivUp(int256(Constants.LTV_DIVIDER), int256(Constants.LTV_DIVIDER - data.targetLTV));
    }

    // in shares case: HODLer <=> depositor/withdrawer conflict, round down to have lower debt in protocol
    // in collateral case: No conflict, round down to have less borrow in the protocol
    function calculateDeltaRealBorrowFromDeltaRealCollateral(
        int256 deltaCollateral,
        int256 realCollateral,
        int256 realBorrow,
        uint128 targetLTV
    ) private pure returns (int256) {
        return
            realCollateral.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER)) +
            deltaCollateral.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER)) -
            realBorrow;
    }

    // Borrow case, no conflict, rounding up to have more collateral in protocol
    function calculateDeltaRealCollateralFromDeltaRealBorrow(
        int256 deltaBorrow,
        int256 realBorrow,
        int256 realCollateral,
        uint128 targetLTV
    ) private pure returns (int256) {
        return (realBorrow + deltaBorrow).mulDivUp(int256(Constants.LTV_DIVIDER), int128(targetLTV)) - realCollateral;
    }

    function calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
        int256 deltaCollateral,
        int256 deltaBorrow,
        int256 futureCollateral,
        int256 userFutureRewardCollateral,
        int256 futureBorrow,
        int256 userFutureRewardBorrow
    ) private pure returns (int256) {
        return deltaCollateral - deltaBorrow - futureCollateral - userFutureRewardCollateral + futureBorrow + userFutureRewardBorrow;
    }

    function calculateLowLevelRebalanceShares(int256 deltaShares, LowLevelRebalanceData memory data) external pure returns (int256, int256, int256) {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (-data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice))
            .mulDivDown(int256(data.supplyAfterFee), int256(data.totalAssets));

        // HODLer <=> depositor/withdrawer conflict, resolve in favor of HODLer, rounding up to assume more minting in case of deposit, or
        // less burning in case of withdraw. It helps to get more assets in case of deposit, or give less assets in case of withdraw.
        int256 deltaSharesInAssets = deltaShares.mulDivUp(int256(data.totalAssets), int256(data.supplyAfterFee));
        int256 deltaSharesInUnderlying = deltaSharesInAssets.mulDivUp(int256(data.borrowPrice), int256(Constants.ORACLE_DIVIDER));

        int256 deltaRealCollateral = calculateDeltaRealCollateralFromDeltaShares(
            DeltaRealCollateralFromDeltaSharesData({
                deltaShares: deltaSharesInUnderlying,
                futureCollateral: data.futureCollateral,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                realCollateral: data.realCollateral,
                realBorrow: data.realBorrow,
                futureBorrow: data.futureBorrow,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                targetLTV: data.targetLTV
            })
        );

        int256 deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, data.realCollateral, data.realBorrow, data.targetLTV);

        // round up to leave more collateral in protocol
        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(data.collateralPrice));
        // round down to leave less borrow in protocol
        int256 deltaRealBorrowAssets = deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice));

        return (deltaRealCollateralAssets, deltaRealBorrowAssets, deltaProtocolFutureRewardShares);
    }

    function calculateLowLevelRebalanceBorrow(
        int256 deltaBorrowAssets,
        LowLevelRebalanceData memory data
    ) external pure returns (int256, int256, int256) {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (-data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice))
            .mulDivDown(int256(data.supplyAfterFee), int256(data.totalAssets));

        int256 deltaRealCollateral;
        int256 deltaSharesInUnderlying;
        {
            // Depositor/withdrawer <=> HODLer conflict, round up to assume smaller debt decrease in case of deposit or bigger debt increase in case of withdraw.
            int256 deltaRealBorrow = deltaBorrowAssets.mulDivUp(int256(data.borrowPrice), int256(Constants.ORACLE_DIVIDER));
            deltaRealCollateral = calculateDeltaRealCollateralFromDeltaRealBorrow(deltaRealBorrow, data.realBorrow, data.realCollateral, data.targetLTV);
            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                data.futureCollateral,
                data.userFutureRewardCollateral,
                data.futureBorrow,
                data.userFutureRewardBorrow
            );
        }

        // HODLer <=> depositor/withdrawer conflict, resolve in favor of HODLer, round down to give less shares
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
            int256(data.supplyAfterFee),
            int256(data.totalAssets)
        );
        // HODLer <=> depositor/withdrawer conflict, resolve in favor of HODLer, round up to keep more collateral in the protocol
        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(data.collateralPrice));

        return (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    function calculateLowLevelRebalanceCollateral(
        int256 deltaCollateralAssets,
        LowLevelRebalanceData memory data
    ) external pure returns (int256, int256, int256) {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (-data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice))
            .mulDivDown(int256(data.supplyAfterFee), int256(data.totalAssets));

        int256 deltaRealBorrow;
        int256 deltaSharesInUnderlying;
        {
            // Depositor/withdrawer <=> HODLer conflict, round down to assume smaller collateral increase in case of deposit or bigger collateral decrease in case of withdraw.
            int256 deltaRealCollateral = deltaCollateralAssets.mulDivDown(int256(data.collateralPrice), int256(Constants.ORACLE_DIVIDER));

            deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, data.realCollateral, data.realBorrow, data.targetLTV);

            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                data.futureCollateral,
                data.userFutureRewardCollateral,
                data.futureBorrow,
                data.userFutureRewardBorrow
            );
        }

        // HODLer <=> depositor/withdrawer conflict, resolving in favor of HODLer, rounding down, less shares minted - bigger token price
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
            int256(data.supplyAfterFee),
            int256(data.totalAssets)
        );
        // HODLer <=> depositor/withdrawer conflict, resolving in favor of HODLer, rounding down to keep less borrow in the protocol
        int256 deltaRealBorrowAssets = deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice));

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }
}
