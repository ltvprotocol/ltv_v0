// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewCollateralVaultData.sol";

struct MaxDepositMintCollateralVaultData {
    PreviewCollateralVaultData previewCollateralVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLTVDividend;
    uint16 minProfitLTVDivider;
}
