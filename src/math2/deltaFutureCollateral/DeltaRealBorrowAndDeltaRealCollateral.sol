// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../structs/data/vault/DeltaRealBorrowAndDeltaRealCollateralData.sol';
import '../../structs/data/vault/Cases.sol';
import '../../Constants.sol';
import 'src/math2/CasesOperator.sol';
import '../../utils/MulDiv.sol';

library DeltaRealBorrowAndDeltaRealCollateral {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    error DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(DeltaRealBorrowAndDeltaRealCollateralData data);

    struct DividendData {
        Cases cases;
        int256 borrow;
        int256 deltaRealBorrow;
        int256 futureCollateral;
        int256 futureBorrow;
        int256 userFutureRewardBorrow;
        int256 userFutureRewardCollateral;
        uint256 borrowSlippage;
        uint256 collateralSlippage;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        int256 collateral;
        int256 deltaRealCollateral;
        uint128 targetLTV;
    }

    struct DividerData {
        Cases cases;
        int256 futureCollateral;
        int256 futureBorrow;
        uint256 collateralSlippage;
        uint256 borrowSlippage;
        int256 collateral;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        uint128 targetLTV;
        int256 userFutureRewardBorrow;
        int256 userFutureRewardCollateral;
    }

    // needs to be rounded down in any case
    function calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
        DividendData memory data
    )
        private
        pure
        returns (
            //bool isUp
            int256
        )
    {
        // dividend:
        //
        // -borrow
        // -ΔrealBorrow
        // -(ceccb + cecbc) x (futureCollateral - futureBorrow)
        // cecbc x userFutureRewardBorrow
        // ceccb x futureCollateral x borrowSlippage
        // cecbc x protocolFutureRewardBorrow
        // targetLTV x collateral
        // targetLTV x ΔrealCollateral
        // targetLTV x ceccb x - userFutureRewardCollateral
        // targetLTV x cecbc x -futureCollateral x collateralSlippage
        // targetLTV x ceccb x - protocolFutureRewardCollateral

        int256 dividend = -int256(data.borrow);
        dividend -= data.deltaRealBorrow;
        dividend -= int256(int8(data.cases.ceccb + data.cases.cecbc)) * (int256(data.futureCollateral) - int256(data.futureBorrow));
        dividend += int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);

        // goes to dividend with plus sign, so need to round down
        dividend += int256(int8(data.cases.ceccb)) * data.futureCollateral.mulDivDown(int256(data.borrowSlippage), 10 ** 18);

        dividend += int256(int8(data.cases.cecbc)) * int256(data.protocolFutureRewardBorrow);

        int256 dividendWithTargetLTV = int256(data.collateral);
        dividendWithTargetLTV += data.deltaRealCollateral;
        dividendWithTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);

        // goes to dividend with minus sign, so needs to be rounded up
        dividendWithTargetLTV -= int256(int8(data.cases.cecbc)) * data.futureCollateral.mulDivUp(int256(data.collateralSlippage), 10 ** 18);

        dividendWithTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.protocolFutureRewardCollateral);

        // goes to dividend with plus sign, so needs to be rounded down
        dividend += dividendWithTargetLTV.mulDivDown(int128(data.targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    // divider always positive
    function calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(DividerData memory data) private pure returns (int256) {
        // divider
        //
        // (cna + cmcb + cmbc + ceccb + cecbc) x 1
        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage
        // cebc x protocolFutureRewardBorrow/futureCollateral
        // - targetLTV x 1
        // - targetLTV x cecb x userFutureRewardCollateral/futureCollateral
        // targetLTV x cmbc x collateralSlippage
        // targetLTV x cecbc x collateralSlippage
        // - targetLTV x cecb x protocolFutureRewardCollateral/futureCollateral

        // translate into 6 parts

        // (cna + cmcb + cmbc + ceccb + cecbc) x 1

        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cebc x protocolFutureRewardBorrow/futureCollateral

        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage

        // - targetLTV x 1

        // - targetLTV x cecb x userFutureRewardCollateral/futureCollateral
        // - targetLTV x cecb x protocolFutureRewardCollateral/futureCollateral

        // targetLTV x cmbc x collateralSlippage
        // targetLTV x cecbc x collateralSlippage

        // part 1
        int256 DIVIDER = 10 ** 18;

        int256 divider = DIVIDER * int256(int8(data.cases.cna + data.cases.cmcb + data.cases.cmbc + data.cases.ceccb + data.cases.cecbc));

        // part 2
        if (data.futureCollateral != 0) {
            int256 dividerDivFutureCollateral = int256(int8(data.cases.cecb + data.cases.cebc)) * int256(data.futureBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.userFutureRewardBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.protocolFutureRewardBorrow);

            // goes to divider with sign plus, so need to round up
            if (data.cases.cecb != 0) {
                dividerDivFutureCollateral = dividerDivFutureCollateral.mulDivDown(DIVIDER, data.futureCollateral);
            } else if (data.cases.cebc != 0) {
                dividerDivFutureCollateral = dividerDivFutureCollateral.mulDivUp(DIVIDER, data.futureCollateral);
            }

            divider += dividerDivFutureCollateral;
        }

        // part 3

        int256 dividerBorrowSlippage = -int256(int8(data.cases.cmcb));
        dividerBorrowSlippage -= int256(int8(data.cases.ceccb));

        dividerBorrowSlippage = dividerBorrowSlippage * int256(data.borrowSlippage);

        divider += dividerBorrowSlippage;

        // part 4-6

        // part 4
        int256 dividerTargetLTV = -DIVIDER;

        // part 5

        if (data.futureCollateral != 0) {
            int256 dividerTargetLTVDivFutureCollateral = -int256(int8(data.cases.cecb)) * int256(data.userFutureRewardCollateral);
            dividerTargetLTVDivFutureCollateral -= int256(int8(data.cases.cecb)) * int256(data.protocolFutureRewardCollateral);
            // takes effect only in cecb case. Since it goes to divider with plus sign, needs to be rounded down
            dividerTargetLTVDivFutureCollateral = dividerTargetLTVDivFutureCollateral.mulDivDown(DIVIDER, int256(data.futureCollateral));
            dividerTargetLTV += dividerTargetLTVDivFutureCollateral;
        }

        // part 6
        int256 dividerTargetLTVCollateralSlippage = int256(int8(data.cases.cmbc));
        dividerTargetLTVCollateralSlippage += int256(int8(data.cases.cecbc));

        dividerTargetLTVCollateralSlippage = dividerTargetLTVCollateralSlippage * int256(data.collateralSlippage);
        dividerTargetLTV += dividerTargetLTVCollateralSlippage;

        if (data.cases.cmcb + data.cases.cebc + data.cases.ceccb != 0) {
            dividerTargetLTV = dividerTargetLTV.mulDivUp(int128(data.targetLTV), int256(Constants.LTV_DIVIDER));
        } else {
            dividerTargetLTV = dividerTargetLTV.mulDivDown(int128(data.targetLTV), int256(Constants.LTV_DIVIDER));
        }

        divider += dividerTargetLTV;

        return divider;
    }

    // These functions are used in Deposit/withdraw/mint/redeem. Since this math implies that deltaTotalAssets = deltaTotalShares, we don't have
    // HODLer conflict here. So the only conflict is between depositor/withdrawer and future executor. For future executor it's better to have smaller
    // futureCollateral, so we need always round delta future collateral to the bottom
    // divider is always positive
    // cna - dividend is 0
    // cmcb, cebc, ceccb - deltaFutureCollateral is positive, so dividend is positive, dividend needs to be rounded down, divider needs to be rounded up
    // cmbc, cecb, cecbc - deltaFutureCollateral is negative, so dividend is negative, dividend needs to be rounded down, divider needs to be rounded down
    function calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) external pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral = 0;
        while (true) {
            int256 dividend = calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
                DividendData({
                    cases: data.cases,
                    borrow: data.borrow,
                    deltaRealBorrow: data.deltaRealBorrow,
                    futureCollateral: data.futureCollateral,
                    futureBorrow: data.futureBorrow,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    userFutureRewardCollateral: data.userFutureRewardCollateral,
                    borrowSlippage: data.borrowSlippage,
                    collateralSlippage: data.collateralSlippage,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    collateral: data.collateral,
                    deltaRealCollateral: data.deltaRealCollateral,
                    targetLTV: data.targetLTV
                })
            );

            int256 divider = calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(DividerData({
                cases: data.cases,
                futureCollateral: data.futureCollateral,
                futureBorrow: data.futureBorrow,
                collateralSlippage: data.collateralSlippage,
                borrowSlippage: data.borrowSlippage,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                targetLTV: data.targetLTV,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral
            }));

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (data.cases.ncase >= 6) {
                    revert DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }

            // round down since we need deltaFutureCollateral to be rounded down
            deltaFutureCollateral = dividend.mulDivDown(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(data.cases, data.futureCollateral, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 6) {
                revert DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
            }

            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureCollateral, data.cases);
    }
}
