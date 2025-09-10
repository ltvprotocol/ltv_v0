// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {Cases} from "src/structs/data/vault/common/Cases.sol";
import {UMulDiv, SMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title CommonBorrowCollateral
 * @notice This library contains functions to calculate state transitions during vault operations.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 */
library CommonBorrowCollateral {
    using UMulDiv for uint256;
    using SMulDiv for int256;

    /**
     * @notice This function calculates deltaFutureBorrow from deltaFutureCollateral.
     *
     * @dev This function calculates deltaFutureBorrow from deltaFutureCollateral.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     *
     * Future executor <=> executor conflict, round up to make auction more profitable
     */
    function calculateDeltaFutureBorrowFromDeltaFutureCollateral(
        Cases memory ncase,
        int256 futureCollateral,
        int256 futureBorrow,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // (cna + cmcb + cmbc + ceccb + cecbc) × ∆futureCollateral +
        // + (cecb + cebc) × ∆futureCollateral × futureBorrow / futureCollateral +
        // + (ceccb + cecbc) × (futureCollateral − futureBorrow)

        int256 deltaFutureBorrow =
            int256(int8(ncase.cna + ncase.cmcb + ncase.cmbc + ncase.ceccb + ncase.cecbc)) * deltaFutureCollateral;
        if (futureCollateral == 0) {
            return deltaFutureBorrow;
        }

        deltaFutureBorrow +=
            int256(int8(ncase.cecb + ncase.cebc)) * deltaFutureCollateral.mulDivUp(futureBorrow, futureCollateral);
        deltaFutureBorrow += int256(int8(ncase.ceccb + ncase.cecbc)) * (futureCollateral - futureBorrow);

        return deltaFutureBorrow;
    }

    /**
     * @notice This function calculates deltaFutureCollateral from deltaFutureBorrow.
     *
     * @dev This function calculates deltaFutureCollateral from deltaFutureBorrow.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * Future executor <=> executor conflict, round down to make auction more profitable
     */
    function calculateDeltaFutureCollateralFromDeltaFutureBorrow(
        Cases memory ncase,
        int256 futureCollateral,
        int256 futureBorrow,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        int256 deltaFutureCollateral =
            int256(int8(ncase.cna + ncase.cmcb + ncase.cmbc + ncase.ceccb + ncase.cecbc)) * deltaFutureBorrow;
        if (futureCollateral == 0) {
            return deltaFutureCollateral;
        }

        deltaFutureCollateral +=
            int256(int8(ncase.cecb + ncase.cebc)) * deltaFutureBorrow.mulDivDown(futureCollateral, futureBorrow);
        deltaFutureCollateral += int256(int8(ncase.ceccb + ncase.cecbc)) * (futureBorrow - futureCollateral);

        return deltaFutureCollateral;
    }

    /**
     * @notice This function calculates deltaUserFutureRewardCollateral from deltaFutureCollateral.
     *
     * @dev This function calculates deltaUserFutureRewardCollateral from deltaFutureCollateral.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * Future executor <=> executor conflict, round down to make auction more profitable
     */
    function calculateDeltaUserFutureRewardCollateral(
        Cases memory ncase,
        int256 futureCollateral,
        int256 userFutureRewardCollateral,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // cecb × userFutureRewardCollateral × ∆futureCollateral / futureCollateral +
        // + ceccb × −userFutureRewardCollateral

        if (futureCollateral == 0) {
            return 0;
        }

        int256 deltaUserFutureRewardCollateral =
            int256(int8(ncase.cecb)) * userFutureRewardCollateral.mulDivDown(deltaFutureCollateral, futureCollateral);
        deltaUserFutureRewardCollateral -= int256(int8(ncase.ceccb)) * userFutureRewardCollateral;
        return deltaUserFutureRewardCollateral;
    }

    /**
     * @notice This function calculates deltaProtocolFutureRewardCollateral from deltaFutureCollateral.
     *
     * @dev This function calculates deltaProtocolFutureRewardCollateral from deltaFutureCollateral.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * Fee collector <=> future executor conflict, round down to leave a bit more future reward collateral in the protocol
     */
    function calculateDeltaProtocolFutureRewardCollateral(
        Cases memory ncase,
        int256 futureCollateral,
        int256 protocolFutureRewardCollateral,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // cecb × userFutureRewardCollateral × ∆futureCollateral / futureCollateral +
        // + ceccb × −userFutureRewardCollateral

        if (futureCollateral == 0) {
            return 0;
        }

        int256 deltaProtocolFutureRewardCollateral =
            int256(int8(ncase.cecb)) * protocolFutureRewardCollateral.mulDivUp(deltaFutureCollateral, futureCollateral);
        deltaProtocolFutureRewardCollateral -= int256(int8(ncase.ceccb)) * protocolFutureRewardCollateral;
        return deltaProtocolFutureRewardCollateral;
    }

    /**
     * @notice This function calculates deltaFuturePaymentCollateral from deltaFutureCollateral.
     *
     * @dev This function calculates deltaFuturePaymentCollateral from deltaFutureCollateral.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * auction creator <=> future executor conflict, resolve in favor of future executor, round down to leave more rewards in protocol
     */
    function calculateDeltaFuturePaymentCollateral(
        Cases memory ncase,
        int256 futureCollateral,
        int256 deltaFutureCollateral,
        uint256 collateralSlippage
    ) internal pure returns (int256) {
        // cmbc × −∆futureCollateral × collateralSlippage +
        // + cecbc × −(∆futureCollateral + futureCollateral) × collateralSlippage

        // casting to int256 is safe because collateralSlippage are considered to be smaller than type(int256).max
        // forge-lint: disable-start(unsafe-typecast)
        int256 deltaFuturePaymentCollateral = -int256(int8(ncase.cmbc))
            * deltaFutureCollateral.mulDivUp(int256(collateralSlippage), Constants.SLIPPAGE_PRECISION);
        deltaFuturePaymentCollateral -= int256(int8(ncase.cecbc))
            * (deltaFutureCollateral + futureCollateral).mulDivUp(int256(collateralSlippage), Constants.SLIPPAGE_PRECISION);
        // forge-lint: disable-end(unsafe-typecast)
        return deltaFuturePaymentCollateral;
    }

    /**
     * @notice This function calculates deltaUserFutureRewardBorrow from deltaFutureBorrow.
     *
     * @dev This function calculates deltaUserFutureRewardBorrow from deltaFutureBorrow.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * auction executor <=> future auction executor conflict, resolve in favor of future executor, round up to leave more rewards in protocol
     */
    function calculateDeltaUserFutureRewardBorrow(
        Cases memory ncase,
        int256 futureBorrow,
        int256 userFutureRewardBorrow,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        // cebc × userF utureRewardBorrow × ∆futureBorrow / futureBorrow +
        // + cecbc × −userFutureRewardBorrow

        if (futureBorrow == 0) {
            return 0;
        }

        int256 deltaUserFutureRewardBorrow =
            int256(int8(ncase.cebc)) * userFutureRewardBorrow.mulDivUp(deltaFutureBorrow, futureBorrow);
        deltaUserFutureRewardBorrow -= int256(int8(ncase.cecbc)) * userFutureRewardBorrow;

        return deltaUserFutureRewardBorrow;
    }

    /**
     * @notice This function calculates deltaProtocolFutureRewardBorrow from deltaFutureBorrow.
     *
     * @dev This function calculates deltaProtocolFutureRewardBorrow from deltaFutureBorrow.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * Fee collector <=> future executor conflict, round up to leave a bit more future reward borrow in the protocol
     */
    function calculateDeltaProtocolFutureRewardBorrow(
        Cases memory ncase,
        int256 futureBorrow,
        int256 protocolFutureRewardBorrow,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        if (futureBorrow == 0) {
            return 0;
        }

        int256 deltaProtocolFutureRewardBorrow =
            int256(int8(ncase.cebc)) * protocolFutureRewardBorrow.mulDivUp(deltaFutureBorrow, futureBorrow);
        deltaProtocolFutureRewardBorrow -= int256(int8(ncase.cecbc)) * protocolFutureRewardBorrow;

        return deltaProtocolFutureRewardBorrow;
    }

    /**
     * @notice This function calculates deltaFuturePaymentBorrow from deltaFutureBorrow.
     *
     * @dev This function calculates deltaFuturePaymentBorrow from deltaFutureBorrow.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * auction creator <=> future executor conflict, resolve in favor of future executor, round up to leave more rewards in protocol
     */
    function calculateDeltaFuturePaymentBorrow(
        Cases memory ncase,
        int256 futureBorrow,
        int256 deltaFutureBorrow,
        uint256 borrowSlippage
    ) internal pure returns (int256) {
        // cmcb × −∆futureBorrow × borrowSlippage +
        // + ceccb × −(∆futureBorrow + futureBorrow) × borrowSlippage

        // casting to int256 is safe because borrowSlippage are considered to be smaller than type(int256).max
        // forge-lint: disable-start(unsafe-typecast)
        int256 deltaFuturePaymentBorrow = -int256(int8(ncase.cmcb))
            * deltaFutureBorrow.mulDivDown(int256(borrowSlippage), Constants.SLIPPAGE_PRECISION);
        deltaFuturePaymentBorrow -= int256(int8(ncase.ceccb))
            * (deltaFutureBorrow + futureBorrow).mulDivDown(int256(borrowSlippage), Constants.SLIPPAGE_PRECISION);
        // forge-lint: disable-end(unsafe-typecast)

        return deltaFuturePaymentBorrow;
    }
}
