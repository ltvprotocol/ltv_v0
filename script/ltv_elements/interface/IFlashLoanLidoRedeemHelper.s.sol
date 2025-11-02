// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IFlashLoanLidoRedeemHelper {
    function previewRedeemSharesWithCurveAndFlashLoanBorrow(uint256 sharesToRedeem)
        external
        view
        returns (uint256 assetsBorrow);
    function redeemSharesWithCurveAndFlashLoanBorrow(uint256 sharesToRedeem, uint256 minWeth)
        external
        returns (uint256 assetsBorrow);
}
