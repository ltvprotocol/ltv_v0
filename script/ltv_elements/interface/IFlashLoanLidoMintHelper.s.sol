// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IFlashLoanLidoMintHelper {
    function previewMintSharesWithFlashLoanCollateral(uint256 sharesToMint)
        external
        view
        returns (uint256 assetsCollateral);
    function mintSharesWithFlashLoanCollateral(uint256 sharesToMint) external returns (uint256 assetsCollateral);
}
