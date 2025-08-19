// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositBorrowVaultData} from "src/structs/data/vault/PreviewDepositBorrowVaultData.sol";

struct MaxDepositMintBorrowVaultData {
    PreviewDepositBorrowVaultData previewDepositBorrowVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
