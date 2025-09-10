// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILowLevelRebalanceErrors} from "src/errors/ILowLevelRebalanceErrors.sol";
import {Constants} from "src/Constants.sol";
import {LowLevelRebalanceData} from "src/structs/data/low_level/LowLevelRebalanceData.sol";
import {DeltaRealCollateralFromDeltaSharesData} from
    "src/structs/data/low_level/DeltaRealCollateralFromDeltaSharesData.sol";
import {SMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title LowLevelRebalanceMath
 * @notice This library contains functions to calculate full state transition in underlying assets
 * for low level rebalance operations.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 */
library LowLevelRebalanceMath {
    using SMulDiv for int256;

    /**
     * @notice This function calculates delta real collateral from delta shares.
     *
     * @dev This function calculates delta real collateral from delta shares.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * HODLer <=> depositor/withdrawer conflict, round up to leave more collateral in protocol
     */
    function calculateDeltaRealCollateralFromDeltaShares(DeltaRealCollateralFromDeltaSharesData memory data)
        private
        pure
        returns (int256)
    {
        return (
            data.deltaShares + data.futureCollateral + data.userFutureRewardCollateral
                + data.realCollateral.mulDivUp(
                    int256(uint256(data.targetLtvDividend)), int256(uint256(data.targetLtvDivider))
                ) - data.realBorrow - data.futureBorrow - data.userFutureRewardBorrow
        )
            // round up to leave more collateral in protocol
            .mulDivUp(
            int256(uint256(data.targetLtvDivider)), int256(uint256(data.targetLtvDivider - data.targetLtvDividend))
        );
    }

    /**
     * @notice This function calculates delta real borrow from delta real collateral.
     *
     * @dev This function calculates delta real borrow from delta real collateral.
     * Calculations are derived from the ltv protocol paper. Hint: next real collateral
     * and new real borrow need to be in targetLtv ratio.
     *
     * ROUNDING:
     * in shares case: HODLer <=> depositor/withdrawer conflict, round down to have lower debt in protocol
     * in collateral case: No conflict, round down to have less borrow in the protocol
     */
    function calculateDeltaRealBorrowFromDeltaRealCollateral(
        int256 deltaCollateral,
        int256 realCollateral,
        int256 realBorrow,
        uint16 targetLtvDividend,
        uint16 targetLtvDivider
    ) private pure returns (int256) {
        return realCollateral.mulDivDown(int256(uint256(targetLtvDividend)), int256(uint256(targetLtvDivider)))
            + deltaCollateral.mulDivDown(int256(uint256(targetLtvDividend)), int256(uint256(targetLtvDivider))) - realBorrow;
    }

    /**
     * @notice This function calculates delta real collateral from delta real borrow.
     *
     * @dev This function calculates delta real collateral from delta real borrow.
     * Calculations are derived from the ltv protocol paper. Hint: next real collateral
     * and new real borrow need to be in targetLtv ratio.
     * ROUNDING:
     * Borrow case, no conflict, rounding up to have more collateral in protocol
     */
    function calculateDeltaRealCollateralFromDeltaRealBorrow(
        int256 deltaBorrow,
        int256 realBorrow,
        int256 realCollateral,
        uint16 targetLtvDividend,
        uint16 targetLtvDivider
    ) private pure returns (int256) {
        if (realBorrow + deltaBorrow == 0) {
            return -realCollateral;
        }

        if (targetLtvDividend == 0) {
            revert ILowLevelRebalanceErrors.ZerotargetLtvDisablesBorrow();
        }
        return (realBorrow + deltaBorrow).mulDivUp(
            int256(uint256(targetLtvDivider)), int256(uint256(targetLtvDividend))
        ) - realCollateral;
    }

    /**
     * @notice This function calculates delta shares from delta real collateral and delta real borrow.
     *
     * @dev This function calculates delta shares from delta real collateral and delta real borrow.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * No conflict, round up to have more shares in protocol
     */
    function calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
        int256 deltaCollateral,
        int256 deltaBorrow,
        int256 futureCollateral,
        int256 userFutureRewardCollateral,
        int256 futureBorrow,
        int256 userFutureRewardBorrow
    ) private pure returns (int256) {
        return deltaCollateral - deltaBorrow - futureCollateral - userFutureRewardCollateral + futureBorrow
            + userFutureRewardBorrow;
    }

    /**
     * @notice From amount of shares user wants to burn or mint, calculates changes in real collateral,
     * real borrow and amount of shares needed to mint to fee collector. Everything is in underlying assets.
     */
    function calculateLowLevelRebalanceShares(int256 deltaShares, LowLevelRebalanceData memory data)
        external
        pure
        returns (int256, int256, int256)
    {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (
            -data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow
        ).mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
            int256(data.supplyAfterFee), int256(data.totalAssets)
        );

        // HODLer <=> depositor/withdrawer conflict, resolve in favor of HODLer, rounding up to assume more minting in case of deposit, or
        // less burning in case of withdraw. It helps to get more assets in case of deposit, or give less assets in case of withdraw.
        int256 deltaSharesInAssets = deltaShares.mulDivUp(int256(data.totalAssets), int256(data.supplyAfterFee));
        int256 deltaSharesInUnderlying =
            deltaSharesInAssets.mulDivUp(int256(data.borrowPrice), int256(Constants.ORACLE_DIVIDER));

        int256 deltaRealCollateral = calculateDeltaRealCollateralFromDeltaShares(
            DeltaRealCollateralFromDeltaSharesData({
                deltaShares: deltaSharesInUnderlying,
                futureCollateral: data.futureCollateral,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                realCollateral: data.realCollateral,
                realBorrow: data.realBorrow,
                futureBorrow: data.futureBorrow,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider
            })
        );

        int256 deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(
            deltaRealCollateral, data.realCollateral, data.realBorrow, data.targetLtvDividend, data.targetLtvDivider
        );

        // round up to leave more collateral in protocol
        int256 deltaRealCollateralAssets =
            deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(data.collateralPrice));
        // round down to leave less borrow in protocol
        int256 deltaRealBorrowAssets =
            deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice));

        return (deltaRealCollateralAssets, deltaRealBorrowAssets, deltaProtocolFutureRewardShares);
    }

    /**
     * @notice From amount of borrow user wants to deposit or withdraw, calculates changes in real collateral,
     * amount of shares needed to mint or burn and amount of shares needed to mint to fee collector. Everything is in underlying assets.
     */
    function calculateLowLevelRebalanceBorrow(int256 deltaBorrowAssets, LowLevelRebalanceData memory data)
        external
        pure
        returns (int256, int256, int256)
    {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (
            -data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow
        ).mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
            int256(data.supplyAfterFee), int256(data.totalAssets)
        );

        int256 deltaRealCollateral;
        int256 deltaSharesInUnderlying;
        {
            // Depositor/withdrawer <=> HODLer conflict, round up to assume smaller debt decrease in case of deposit or bigger debt increase in case of withdraw.
            int256 deltaRealBorrow =
                deltaBorrowAssets.mulDivUp(int256(data.borrowPrice), int256(Constants.ORACLE_DIVIDER));
            deltaRealCollateral = calculateDeltaRealCollateralFromDeltaRealBorrow(
                deltaRealBorrow, data.realBorrow, data.realCollateral, data.targetLtvDividend, data.targetLtvDivider
            );
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
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(
            int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)
        ).mulDivDown(int256(data.supplyAfterFee), int256(data.totalAssets));
        // HODLer <=> depositor/withdrawer conflict, resolve in favor of HODLer, round up to keep more collateral in the protocol
        int256 deltaRealCollateralAssets =
            deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(data.collateralPrice));

        return (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    /**
     * @notice From amount of collateral user wants to deposit or withdraw, calculates changes in real borrow,
     * amount of shares needed to mint or burn and amount of shares needed to mint to fee collector. Everything is in underlying assets.
     */
    function calculateLowLevelRebalanceCollateral(int256 deltaCollateralAssets, LowLevelRebalanceData memory data)
        external
        pure
        returns (int256, int256, int256)
    {
        // HODLer <=> Fee collector conflict, resolve in favor of HODLer, round down to give less rewards
        int256 deltaProtocolFutureRewardShares = (
            -data.protocolFutureRewardCollateral + data.protocolFutureRewardBorrow
        ).mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
            int256(data.supplyAfterFee), int256(data.totalAssets)
        );

        int256 deltaRealBorrow;
        int256 deltaSharesInUnderlying;
        {
            // Depositor/withdrawer <=> HODLer conflict, round down to assume smaller collateral increase in case of deposit or bigger collateral decrease in case of withdraw.
            int256 deltaRealCollateral =
                deltaCollateralAssets.mulDivDown(int256(data.collateralPrice), int256(Constants.ORACLE_DIVIDER));

            deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(
                deltaRealCollateral, data.realCollateral, data.realBorrow, data.targetLtvDividend, data.targetLtvDivider
            );

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
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(
            int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)
        ).mulDivDown(int256(data.supplyAfterFee), int256(data.totalAssets));
        // HODLer <=> depositor/withdrawer conflict, resolving in favor of HODLer, rounding down to keep less borrow in the protocol
        int256 deltaRealBorrowAssets =
            deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice));

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }
}
