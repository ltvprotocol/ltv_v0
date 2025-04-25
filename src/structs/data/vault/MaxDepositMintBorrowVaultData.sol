// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewBorrowVaultData.sol";

struct MaxDepositMintBorrowVaultData {
    PreviewBorrowVaultData previewBorrowVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint256 minProfitLTV;
} 